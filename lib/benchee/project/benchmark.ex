defmodule Benchee.Project.Benchmark do
  @moduledoc """
  Module with macro for defining project-wide benchmarks.
  """
  require Logger

  def benchee_scenario_attr, do: :benchee_benchmarks

  @doc """
  Module-scope setup. Optional.

  Must return {:ok, state} for actual benchmark to start.
  """
  defmacro before_all(_opts \\ [], do: doblock) do
    quote do
      def before_all do
        unquote(doblock)
      end
    end
  end

  @doc """
  Module-scope teardown. Optional

  Can return anything.
  """
  defmacro after_all(_opts \\ [], do: doblock) do
    quote do
      def after_all(state) do
        unquote(doblock)
      end
    end
  end

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defmacro benchmark(name, opts \\ [], do: {:__block__, [], exprs}) do
    state_var = atom_to_var(:state)

    run_fun_name = make_fun_name(name)

    inputs = make_inputs(exprs, opts)
    scenarios = make_scenarios(exprs, inputs)

    before_benchmark = make_before_benchmark(exprs, state_var)
    after_benchmark = make_after_benchmark(exprs, state_var)

    opts =
      case inputs do
        [] -> opts
        [_ | _] -> Keyword.put(opts, :inputs, inputs)
      end

    quote generated: true do
      @unquote(benchee_scenario_attr())(unquote(run_fun_name))
      def unquote(run_fun_name)(unquote(state_var), opts \\ []) do
        opts = DeepMerge.deep_merge(opts, unquote(opts))

        case unquote(before_benchmark).(unquote(state_var)) do
          {:ok, unquote(state_var)} ->
            Benchee.run(unquote({:%{}, [], scenarios}), opts)
            unquote(after_benchmark).(unquote(state_var))

          other ->
            :ok =
              Logger.error(
                "Local setup of \"#{unquote(name)}\" in " <>
                  "#{inspect(__MODULE__)} returned #{inspect(other)}"
              )
        end
      end
    end
  end

  defp make_fun_name(name) do
    ["run", :erlang.unique_integer() |> Integer.to_string(), name]
    |> Enum.join("_")
    |> String.to_atom()
  end

  defp make_inputs(exprs, opts) do
    inputs_dsl =
    for {:input, _, [name, expr]} <- exprs do
      {name,
       quote do
         unquote(block_to_fun(expr)).()
       end}
    end
    Keyword.get(opts, :inputs, []) ++ inputs_dsl
  end

  defp make_scenarios(exprs, inputs) do
    case_args =
      case length(inputs) do
        0 -> []
        _ -> [:input]
      end

    for {:scenario, _, args} <- exprs do
      case args do
        [name, block] ->
          {name, block_to_fun(block, case_args)}

        [name, opts, block] ->
          {name, {block_to_fun(block, case_args), opts}}
      end
    end
  end

  defp make_before_benchmark(exprs, state_var) do
    [before_doblock | rest] =
      (exprs
       |> Enum.filter(fn t -> elem(t, 0) == :before_benchmark end)
       |> Enum.map(fn {:before_benchmark, _, [[do: doblock]]} -> doblock end)
      ) ++
      [quote generated: true do {:ok, unquote(state_var)} end]

    before_benchmark = block_to_fun(before_doblock, [:state])

    if length(rest) > 1 do
      raise "Multiple before_benchmark found: only one is required"
    end

    before_benchmark
  end

  defp make_after_benchmark(exprs, state_var) do
    [after_doblock | rest] =
      (exprs
       |> Enum.filter(fn t -> elem(t, 0) == :after_benchmark end)
       |> Enum.map(fn {:after_benchmark, _, [[do: doblock]]} -> doblock end)
      ) ++
      [quote do {:ok, unquote(state_var)} end]

    after_benchmark = block_to_fun(after_doblock, [:state])

    if length(rest) > 1 do
      raise "Multiple after_benchmark found: only one is required"
    end

    after_benchmark
  end

  defmacro __using__(_) do
    quote do
      require Logger

      Module.register_attribute(__MODULE__, unquote(benchee_scenario_attr()),
        persist: true,
        accumulate: true
      )

      import Benchee.Project.Benchmark,
        only: [
          before_all: 1,
          after_all: 1,
          benchmark: 2, benchmark: 3
        ]
    end
  end

  # Helpers
  defp quote_put_attrs({name, base_attrs, args}, attrs) do
    {name, Keyword.merge(base_attrs, attrs), args}
  end

  defp atom_to_var(atom, module \\ nil) do
    atom
    |> Macro.var(module)
    |> quote_put_attrs(generated: true)
  end

  defp block_to_fun(doblock, args \\ [])

  defp block_to_fun([do: doblock], args),
    do: block_to_fun(doblock, args)

  defp block_to_fun(doblock, args) do
    case Enum.map(args, &atom_to_var/1) do
      [] ->
        quote do
          fn -> unquote(doblock) end
        end

      argvars ->
        quote do
          fn unquote_splicing(argvars) -> unquote(doblock) end
        end
    end
  end
end
