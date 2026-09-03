# loadsmart-techtest

## How to Run the Text-to-SQL Agent

1. **Set up your Python environment:**
   pip install -r requirements.txt

2. **Build the dbt models and generate artifacts:**
   cd loadsmart
   dbt run
   dbt compile
   cd ..

3. **Ensure Ollama is running locally:**
   Make sure you have [Ollama](https://ollama.com) installed and pull the required model:
   ollama pull llama3

4. **Run the Jupyter Notebook:**
   Open `text_to_sql_challenge.ipynb` in VS Code and execute the cells.