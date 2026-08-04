import Foundation

extension CleanupCatalog {
    static let localModelRules: [CleanupRule] = [
        rule(
            "lm-studio-models",
            .localModels,
            "LM Studio models",
            "Downloaded model",
            "Models downloaded for local use in LM Studio.",
            "The selected model must be downloaded again before it can be used.",
            .reviewRequired,
            ".lmstudio/models",
            .children,
            .child,
            .deleteItem,
            ["ai.elementlabs.lmstudio"]
        ),
        readOnlyRule(
            "lm-studio-app-models",
            .localModels,
            "LM Studio app models",
            "Models and related metadata stored under LM Studio's app data.",
            "Manage these models from LM Studio so its records remain consistent.",
            .home(relativePath: "Library/Application Support/LM Studio/models"),
            .children,
            .child
        ),
        rule(
            "whisper-models",
            .localModels,
            "Speech recognition models",
            "Downloaded model",
            "Models downloaded for local speech recognition.",
            "The selected model must be downloaded again before it can be used.",
            .reviewRequired,
            ".cache/whisper",
            .children,
            .child,
            .deleteItem
        ),
        readOnlyRule(
            "ollama-data",
            .localModels,
            "Ollama models",
            "Downloaded models managed by Ollama.",
            "Remove models from Ollama so its manifest and blob records stay consistent.",
            .home(relativePath: ".ollama/models"),
            .children,
            .child
        ),
        readOnlyRule(
            "hugging-face-data",
            .localModels,
            "Hugging Face cache",
            "Downloaded models, datasets, spaces, and shared content-addressed blobs.",
            "Use Hugging Face cache tools to avoid breaking shared snapshots.",
            .home(relativePath: ".cache/huggingface"),
            .children,
            .child
        ),
        rule(
            "pytorch-hub-models",
            .localModels,
            "PyTorch Hub models",
            "Downloaded model",
            "Models and weights downloaded through PyTorch Hub.",
            "The selected model or weights must be downloaded again before use.",
            .reviewRequired,
            ".cache/torch/hub",
            .children,
            .child,
            .deleteItem
        ),
        rule(
            "keras-downloads",
            .localModels,
            "Keras downloads",
            "Keras download",
            "Downloaded datasets and models retained by Keras.",
            "The selected data must be downloaded again before it can be used.",
            .reviewRequired,
            ".keras",
            .matchingDirectories(
                names: ["datasets", "models"],
                extensions: [],
                requiredAncestorExtensions: [],
                maximumDepth: 1
            ),
            .child,
            .deleteItem
        ),
        rule(
            "modelscope-cache",
            .localModels,
            "ModelScope cache",
            "Downloaded model",
            "Models and datasets downloaded through ModelScope.",
            "The selected data must be downloaded again before it can be used.",
            .reviewRequired,
            ".cache/modelscope",
            .children,
            .child,
            .deleteItem
        ),
        readOnlyRule(
            "gpt4all-models",
            .localModels,
            "GPT4All models",
            "Downloaded models and related GPT4All application data.",
            "Manage these models from GPT4All.",
            .home(relativePath: "Library/Application Support/nomic.ai/GPT4All"),
            .children,
            .child
        ),
        readOnlyRule(
            "gpt4all-legacy-models",
            .localModels,
            "Legacy GPT4All models",
            "Downloaded models retained by older GPT4All versions.",
            "Import or remove these models from GPT4All after confirming they are unused.",
            .home(relativePath: "Library/Application Support/GPT4All"),
            .children,
            .child
        ),
        readOnlyRule(
            "jan-models",
            .localModels,
            "Jan models",
            "Downloaded models managed by Jan.",
            "Manage these models from Jan so its records remain consistent.",
            .home(relativePath: "Library/Application Support/Jan/data/models"),
            .children,
            .child
        ),
        readOnlyRule(
            "msty-models",
            .localModels,
            "Msty models",
            "Downloaded models managed by Msty.",
            "Manage these models from Msty so its records remain consistent.",
            .home(relativePath: "Library/Application Support/Msty/models"),
            .children,
            .child
        ),
        readOnlyRule(
            "anythingllm-models",
            .localModels,
            "AnythingLLM models",
            "Downloaded models managed by AnythingLLM Desktop.",
            "Manage these models from AnythingLLM so its records remain consistent.",
            .home(
                relativePath: "Library/Application Support/anythingllm-desktop/storage/models"
            ),
            .children,
            .child
        ),
        readOnlyRule(
            "open-webui-data",
            .localModels,
            "Open WebUI data",
            "Chats, databases, uploads, and local model-related application data.",
            "Back up and manage this data from Open WebUI.",
            .home(relativePath: ".open-webui"),
            .children,
            .child
        ),
        readOnlyRule(
            "diffusionbee-data",
            .localModels,
            "DiffusionBee models",
            "Downloaded image-generation models and application data.",
            "Manage these models from DiffusionBee.",
            .home(relativePath: "Library/Application Support/DiffusionBee"),
            .children,
            .child
        ),
        readOnlyRule(
            "pinokio-data",
            .localModels,
            "Pinokio applications and models",
            "Installed AI applications, environments, repositories, and model files.",
            "Manage installed applications from Pinokio to preserve their environments.",
            .home(relativePath: "pinokio"),
            .children,
            .child
        )
    ]
}
