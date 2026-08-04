import Foundation

extension CleanupCatalog {
    static let largeDataRules: [CleanupRule] = [
        managedDataRule(
            "virtual-machines",
            name: "Virtual machines",
            detail: "Complete virtual computers and their files.",
            consequence: "Remove a virtual machine from the app that created it.",
            path: "Virtual Machines.localized"
        ),
        managedDataRule(
            "documents-virtual-machines",
            name: "Virtual machines in Documents",
            detail: "Complete virtual computers and their files.",
            consequence: "Remove a virtual machine from the app that created it.",
            path: "Documents/Virtual Machines.localized"
        ),
        managedDataRule(
            "parallels-virtual-machines",
            name: "Parallels virtual machines",
            detail: "Virtual computers managed by Parallels Desktop.",
            consequence: "Remove or archive these machines from Parallels Desktop.",
            path: "Parallels"
        ),
        managedDataRule(
            "documents-parallels-virtual-machines",
            name: "Parallels virtual machines",
            detail: "Virtual computers managed by Parallels Desktop.",
            consequence: "Remove or archive these machines from Parallels Desktop.",
            path: "Documents/Parallels"
        ),
        managedDataRule(
            "virtualbox-machines",
            name: "VirtualBox machines",
            detail: "Virtual computers managed by VirtualBox.",
            consequence: "Remove or archive these machines from VirtualBox.",
            path: "VirtualBox VMs"
        ),
        managedDataRule(
            "utm-machines",
            name: "UTM virtual machines",
            detail: "Virtual computers, drives, and saved state managed by UTM.",
            consequence: "Remove or archive these machines from UTM.",
            path: "Library/Containers/com.utmapp.UTM/Data/Documents"
        ),
        managedDataRule(
            "docker-desktop-data",
            name: "Docker Desktop data",
            detail: "The Linux disk image containing containers, images, volumes, and build data.",
            consequence: "Use Docker Desktop or Docker commands to remove unused data safely.",
            path: "Library/Containers/com.docker.docker/Data/vms",
            source: .location,
            nameStyle: .fixed
        ),
        managedDataRule(
            "docker-desktop-new-data",
            name: "Docker Desktop data",
            detail: "The Linux disk image containing containers, images, volumes, and build data.",
            consequence: "Use Docker Desktop or Docker commands to remove unused data safely.",
            path: ".docker/desktop/vms",
            source: .location,
            nameStyle: .fixed
        ),
        managedDataRule(
            "podman-machines",
            name: "Podman machines",
            detail: "Linux virtual machines containing Podman images, containers, and volumes.",
            consequence: "Manage these machines with Podman.",
            path: ".local/share/containers/podman/machine"
        ),
        managedDataRule(
            "lima-machines",
            name: "Lima virtual machines",
            detail: "Linux virtual machines, disks, and instance state managed by Lima.",
            consequence: "Manage these instances with Lima.",
            path: ".lima"
        ),
        managedDataRule(
            "colima-machines",
            name: "Colima virtual machines",
            detail: "Container virtual machines, disks, and runtime data managed by Colima.",
            consequence: "Manage these profiles with Colima.",
            path: ".colima"
        ),
        managedDataRule(
            "orbstack-data",
            name: "OrbStack machines and containers",
            detail: "Linux machines, containers, images, and volumes managed by OrbStack.",
            consequence: "Manage this storage from OrbStack.",
            path: "Library/Group Containers/HUAQ24HBR6.dev.orbstack"
        ),
        managedDataRule(
            "vagrant-boxes",
            name: "Vagrant boxes",
            detail: "Downloaded base machine images and Vagrant-managed state.",
            consequence: "Remove unused boxes with Vagrant so its records remain consistent.",
            path: ".vagrant.d/boxes"
        ),
        managedDataRule(
            "whisky-bottles",
            name: "Whisky bottles",
            detail: "Windows applications, game files, and configuration stored in Whisky bottles.",
            consequence: "Remove bottles from Whisky to avoid losing app or game data unexpectedly.",
            path: "Library/Containers/com.isaacmarovitz.Whisky/Bottles"
        ),
        managedDataRule(
            "whisky-app-data",
            name: "Whisky application data",
            detail: "Windows bottles, applications, game files, and support data managed by Whisky.",
            consequence: "Remove bottles and programs from Whisky.",
            path: "Library/Application Support/com.isaacmarovitz.Whisky"
        ),
        managedDataRule(
            "crossover-bottles",
            name: "CrossOver bottles",
            detail: "Windows applications and their data stored in CrossOver bottles.",
            consequence: "Remove bottles from CrossOver after preserving any needed files.",
            path: "Library/Application Support/CrossOver/Bottles"
        ),
        managedDataRule(
            "wine-prefix",
            name: "Wine prefix",
            detail: "Windows applications, settings, and user files stored by Wine.",
            consequence: "Back up needed Windows files before removing a Wine prefix.",
            path: ".wine",
            source: .location,
            nameStyle: .fixed
        ),
        managedDataRule(
            "rancher-desktop-data",
            name: "Rancher Desktop data",
            detail: "Virtual-machine disks, container images, volumes, and Kubernetes data.",
            consequence: "Manage or reset this storage from Rancher Desktop.",
            path: "Library/Application Support/rancher-desktop",
            source: .location,
            nameStyle: .fixed
        ),
        managedDataRule(
            "minikube-data",
            name: "Minikube clusters",
            detail: "Local Kubernetes clusters, virtual disks, images, and profiles.",
            consequence: "Delete unused clusters and profiles with Minikube.",
            path: ".minikube"
        ),
        readOnlyRule(
            "multipass-data",
            .largeAppData,
            "Multipass virtual machines",
            "Linux virtual machines and disks managed by Multipass.",
            "Manage these instances with Multipass.",
            .absolute(path: "/private/var/root/Library/Application Support/multipassd"),
            .children,
            .child
        ),
        readOnlyRule(
            "photos-libraries",
            .largeAppData,
            "Photos libraries",
            "Photos, videos, edits, indexes, and originals managed by Photos.",
            "Move or optimize a library from Photos; never remove files inside its package.",
            .home(relativePath: "Pictures"),
            .matchingDirectories(
                names: [],
                extensions: ["photoslibrary", "photolibrary"],
                requiredAncestorExtensions: [],
                maximumDepth: 3
            ),
            .child
        ),
        readOnlyRule(
            "final-cut-libraries",
            .largeAppData,
            "Final Cut libraries",
            "Projects, events, original media, and generated data managed by Final Cut Pro.",
            "Consolidate, move, or delete libraries from Final Cut Pro.",
            .home(relativePath: "Movies"),
            .matchingDirectories(
                names: [],
                extensions: ["fcpbundle"],
                requiredAncestorExtensions: [],
                maximumDepth: 3
            ),
            .child
        ),
        readOnlyRule(
            "imovie-libraries",
            .largeAppData,
            "iMovie libraries",
            "Projects, events, original media, and generated data managed by iMovie.",
            "Move or delete libraries from iMovie after confirming they are backed up.",
            .home(relativePath: "Movies"),
            .matchingDirectories(
                names: [],
                extensions: ["imovielibrary"],
                requiredAncestorExtensions: [],
                maximumDepth: 3
            ),
            .child
        ),
        managedDataRule(
            "cloud-storage",
            name: "Cloud storage",
            detail: "Local copies of files managed by cloud services.",
            consequence: "Use the cloud service to remove downloads without deleting cloud files.",
            path: "Library/CloudStorage"
        ),
        managedDataRule(
            "icloud-mobile-documents",
            name: "iCloud app documents",
            detail: "Local copies and metadata for documents managed through iCloud.",
            consequence: "Use Finder or the owning app to remove local downloads safely.",
            path: "Library/Mobile Documents"
        ),
        managedDataRule(
            "legacy-dropbox-data",
            name: "Legacy Dropbox folder",
            detail: "Local files managed by an older Dropbox configuration.",
            consequence: "Use Dropbox selective sync or online-only controls.",
            path: "Dropbox"
        ),
        managedDataRule(
            "legacy-onedrive-data",
            name: "Legacy OneDrive folder",
            detail: "Local files managed by an older OneDrive configuration.",
            consequence: "Use OneDrive Files On-Demand controls.",
            path: "OneDrive"
        ),
        managedDataRule(
            "legacy-google-drive-data",
            name: "Legacy Google Drive folder",
            detail: "Local files managed by an older Google Drive configuration.",
            consequence: "Use Google Drive streaming or mirroring controls.",
            path: "Google Drive"
        ),
        managedDataRule(
            "mail-data",
            name: "Mail",
            detail: "Messages, attachments, and indexes kept by Mail.",
            consequence: "Manage this storage from Mail to avoid removing messages unexpectedly.",
            path: "Library/Mail"
        ),
        managedDataRule(
            "messages-data",
            name: "Messages",
            detail: "Messages and attachments stored on this Mac.",
            consequence: "Manage this storage from Messages or macOS Storage settings.",
            path: "Library/Messages",
            source: .location,
            nameStyle: .fixed
        ),
        managedDataRule(
            "music-media",
            name: "Music library media",
            detail: "Music, artwork, and other media managed by the Music app.",
            consequence: "Remove downloads or move the library from Music.",
            path: "Music/Music/Media"
        ),
        managedDataRule(
            "tv-media",
            name: "TV library media",
            detail: "Downloaded movies and shows managed by the TV app.",
            consequence: "Remove downloaded items from the TV app.",
            path: "Movies/TV/Media"
        ),
        managedDataRule(
            "steam-installed-games",
            name: "Steam games",
            detail: "Installed games and application files managed by Steam.",
            consequence: "Uninstall or move games from Steam.",
            path: "Library/Application Support/Steam/steamapps/common"
        ),
        managedDataRule(
            "steam-compatibility-prefixes",
            name: "Steam compatibility data",
            detail: "Windows compatibility environments and game-specific user data.",
            consequence: "Manage this data from Steam; a prefix may contain saves or settings.",
            path: "Library/Application Support/Steam/steamapps/compatdata"
        ),
        managedDataRule(
            "spotify-offline-data",
            name: "Spotify offline audio",
            detail: "Downloaded and cached audio managed by Spotify.",
            consequence: "Manage downloads and storage from Spotify.",
            path: "Library/Application Support/Spotify/PersistentCache"
        ),
        managedDataRule(
            "android-sdk",
            name: "Android SDK",
            detail: "Android platforms, system images, build tools, emulators, and sources.",
            consequence: "Remove unused components from Android Studio's SDK Manager.",
            path: "Library/Android/sdk"
        ),
        managedDataRule(
            "rust-toolchains",
            name: "Rust toolchains",
            detail: "Compiler toolchains, standard libraries, documentation, and components.",
            consequence: "Remove unused toolchains and components with rustup.",
            path: ".rustup/toolchains"
        ),
        managedDataRule(
            "uv-python-installations",
            name: "uv Python installations",
            detail: "Python runtimes installed and managed by uv.",
            consequence: "Remove unused Python versions with uv.",
            path: ".local/share/uv/python"
        ),
        managedDataRule(
            "dotnet-installations",
            name: ".NET installations",
            detail: "SDKs, runtimes, workloads, tools, and related .NET data.",
            consequence: "Remove versions and workloads with .NET-aware tooling.",
            path: ".dotnet"
        ),
        managedDataRule(
            "nvm-node-installations",
            name: "nvm Node.js installations",
            detail: "Node.js runtimes installed and managed by nvm.",
            consequence: "Remove unused versions with nvm.",
            path: ".nvm/versions"
        ),
        managedDataRule(
            "fnm-node-installations",
            name: "fnm Node.js installations",
            detail: "Node.js runtimes installed and managed by fnm.",
            consequence: "Remove unused versions with fnm.",
            path: "Library/Application Support/fnm/node-versions"
        ),
        managedDataRule(
            "volta-toolchains",
            name: "Volta toolchains",
            detail: "Node.js runtimes and package tools installed by Volta.",
            consequence: "Manage pinned runtimes and tools with Volta.",
            path: ".volta/tools"
        ),
        managedDataRule(
            "pyenv-installations",
            name: "pyenv Python installations",
            detail: "Python runtimes installed and managed by pyenv.",
            consequence: "Remove unused Python versions with pyenv.",
            path: ".pyenv/versions"
        ),
        managedDataRule(
            "mise-installations",
            name: "mise tool installations",
            detail: "Language runtimes and developer tools installed by mise.",
            consequence: "Remove unused versions with mise.",
            path: ".local/share/mise/installs"
        ),
        managedDataRule(
            "asdf-installations",
            name: "asdf tool installations",
            detail: "Language runtimes and developer tools installed by asdf.",
            consequence: "Remove unused versions with asdf.",
            path: ".asdf/installs"
        ),
        managedDataRule(
            "rbenv-installations",
            name: "rbenv Ruby installations",
            detail: "Ruby runtimes installed and managed by rbenv.",
            consequence: "Remove unused Ruby versions with rbenv.",
            path: ".rbenv/versions"
        ),
        managedDataRule(
            "miniconda-installation",
            name: "Miniconda environments",
            detail: "Python environments, packages, and caches managed by Conda.",
            consequence: "Remove unused environments and packages with Conda.",
            path: "miniconda3"
        ),
        managedDataRule(
            "anaconda-installation",
            name: "Anaconda environments",
            detail: "Python environments, packages, and caches managed by Conda.",
            consequence: "Remove unused environments and packages with Conda.",
            path: "anaconda3"
        ),
        managedDataRule(
            "vscode-extensions",
            name: "Visual Studio Code extensions",
            detail: "Installed editor extensions and their files.",
            consequence: "Uninstall extensions from Visual Studio Code.",
            path: ".vscode/extensions"
        ),
        managedDataRule(
            "vscode-insiders-extensions",
            name: "Visual Studio Code Insiders extensions",
            detail: "Installed editor extensions and their files.",
            consequence: "Uninstall extensions from Visual Studio Code Insiders.",
            path: ".vscode-insiders/extensions"
        ),
        managedDataRule(
            "cursor-extensions",
            name: "Cursor extensions",
            detail: "Installed editor extensions and their files.",
            consequence: "Uninstall extensions from Cursor.",
            path: ".cursor/extensions"
        ),
        readOnlyRule(
            "storagescope-recovery",
            .systemManaged,
            "Cleanup recovery files",
            "Files StorageScope keeps temporarily so an interrupted cleanup can be restored.",
            "These files protect in-progress cleanup operations and cannot be removed here.",
            .home(relativePath: "Library/Application Support/StorageScope"),
            .location,
            .fixed
        ),
        managedDataRule(
            "application-support",
            name: "App data",
            detail: "Documents, downloads, databases, and support files kept by apps.",
            consequence: "Remove this data from the app that owns it.",
            path: "Library/Application Support"
        ),
        managedDataRule(
            "app-containers",
            name: "App storage",
            detail: "Private documents, settings, downloads, and databases kept by apps.",
            consequence: "Remove this data from the app that owns it.",
            path: "Library/Containers"
        ),
        managedDataRule(
            "group-containers",
            name: "Shared app storage",
            detail: "Documents and settings shared by related apps.",
            consequence: "Remove this data from the app that owns it.",
            path: "Library/Group Containers"
        ),
        readOnlyRule(
            "homebrew-apple-silicon-installations",
            .developer,
            "Homebrew packages",
            "Installed formula versions under the Apple silicon Homebrew prefix.",
            "Uninstall unused formulae with Homebrew.",
            .absolute(path: "/opt/homebrew/Cellar"),
            .children,
            .child
        ),
        readOnlyRule(
            "homebrew-intel-installations",
            .developer,
            "Homebrew packages",
            "Installed formula versions under the Intel Homebrew prefix.",
            "Uninstall unused formulae with Homebrew.",
            .absolute(path: "/usr/local/Cellar"),
            .children,
            .child
        ),
        readOnlyRule(
            "nix-store",
            .developer,
            "Nix store",
            "Packages, runtimes, build outputs, and environments managed by Nix.",
            "Use Nix garbage collection and profile commands.",
            .absolute(path: "/nix/store"),
            .children,
            .child
        ),
        readOnlyRule(
            "macports-installation",
            .developer,
            "MacPorts installation",
            "Installed ports, archives, build state, and package-manager data.",
            "Uninstall inactive or unused ports with MacPorts.",
            .absolute(path: "/opt/local"),
            .children,
            .child
        )
    ]

    private static func managedDataRule(
        _ id: String,
        name: String,
        detail: String,
        consequence: String,
        path: String,
        source: CandidateSource = .children,
        nameStyle: ItemNameStyle = .child
    ) -> CleanupRule {
        CleanupRule(
            id: id,
            category: .largeAppData,
            locationName: name,
            itemTitle: name,
            itemDetail: detail,
            consequence: consequence,
            safety: .reviewRequired,
            location: .home(relativePath: path),
            source: source,
            nameStyle: nameStyle,
            cleanupAction: .deleteItem,
            blockedBundleIdentifiers: []
        )
    }
}
