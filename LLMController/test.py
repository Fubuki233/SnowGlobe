import os
from google import genai
from google.genai import types

# Function declaration for map generation
map_passer_declaration = {
    "name": "map_passer",
    "description": "Pass the generated 2D map.",
    "parameters": {
        "type": "object",
        "properties": {
            "map": {
                "type": "array",
                "description": "A 2D map represented as a list of lists, where each inner list represents a row in the map. Each cell in the map can be either a wall (#) or a path (.).",
                "items": {
                    "type": "array",
                    "items": {
                        "type": "string"
                    }
                }
            },
        },
        "required": ["map"],
    },
}


def map_passer(map_data):
    """Process and return the generated map."""
    return map_data


def main():
    # Load API key from environment variable for security
    api_key = os.getenv("GOOGLE_API_KEY", "AIzaSyAYEeSNAB9ikYV4GoTK-5CM51yE5ljAQYs")
    client = genai.Client(api_key=api_key)

    # Configure tools and content
    tools = types.Tool(function_declarations=[map_passer_declaration])
    contents = [
        types.Content(
            role="user",
            parts=[types.Part(text="Generate a 2D 5X5 map using the defined function.")]
        )
    ]
    
    # Generate content with configured tools
    config = types.GenerateContentConfig(
        tools=[tools],
        thinking_config=types.ThinkingConfig(thinking_level="low")
    )
    
    response = client.models.generate_content(
        model="gemini-3-pro-preview",
        contents=contents,
        config=config,
    )

  
    print(response.candidates[0].content.parts[0].function_call.args)


if __name__ == "__main__":
    main()