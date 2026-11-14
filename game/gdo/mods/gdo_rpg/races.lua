-- Données originales de races inspirées du fichier custom_races/races.json de NLite.
-- Les modèles, icônes et scripts Forge du modpack ne sont pas redistribués ici.
return {
    centaur = {
        name = "Centaure",
        description = "Cavalier quadrupède : charge puissante et grande endurance.",
        hp = 5, speed = 1.12, jump = 1.05, mana = 0, stamina = 25, damage = 1,
        ability = "Charge du centaure", resource = "stamina", cost = 25,
    },
    blazeborn = {
        name = "Né-de-la-flamme",
        description = "Être incandescent : affinité magique et souffle brûlant.",
        hp = 1, speed = 1.02, jump = 1.0, mana = 20, stamina = 0, damage = 1,
        ability = "Souffle ardent", resource = "mana", cost = 25,
    },
    enderian = {
        name = "Endérien",
        description = "Voyageur du vide : téléportation courte et mobilité.",
        hp = -1, speed = 1.08, jump = 1.08, mana = 25, stamina = 0, damage = 0,
        ability = "Pas du vide", resource = "mana", cost = 25,
    },
    feline = {
        name = "Félin",
        description = "Prédateur agile : bond puissant et déplacements silencieux.",
        hp = -2, speed = 1.18, jump = 1.3, mana = 0, stamina = 20, damage = 0,
        ability = "Bond du chasseur", resource = "stamina", cost = 20,
    },
    golem = {
        name = "Golem",
        description = "Colosse de pierre : résistance élevée, mais déplacements lourds.",
        hp = 12, speed = 0.82, jump = 0.88, mana = 0, stamina = 25, damage = 2,
        ability = "Mur de granit", resource = "stamina", cost = 25,
    },
    arachnid = {
        name = "Arachnide",
        description = "Tisseur des ombres : venin et sens de la chasse.",
        hp = 0, speed = 1.08, jump = 1.12, mana = 10, stamina = 10, damage = 0,
        ability = "Venin rampant", resource = "mana", cost = 20,
    },
    merling = {
        name = "Merling",
        description = "Enfant des abysses : souffle et récupération surnaturels.",
        hp = 1, speed = 1.05, jump = 1.0, mana = 15, stamina = 20, damage = 0,
        ability = "Marée réparatrice", resource = "mana", cost = 20,
    },
    dwarf = {
        name = "Nain",
        description = "Mineur robuste : constitution solide et vigueur souterraine.",
        hp = 6, speed = 0.94, jump = 0.92, mana = 0, stamina = 20, damage = 1,
        ability = "Détermination naine", resource = "stamina", cost = 20,
    },
    dragonkin = {
        name = "Sang-dragon",
        description = "Descendant des dragons : force, écailles et cri terrifiant.",
        hp = 6, speed = 1.06, jump = 1.12, mana = 15, stamina = 15, damage = 2,
        ability = "Rugissement draconique", resource = "stamina", cost = 25,
    },
    elf = {
        name = "Elfe",
        description = "Gardien de la nature : agilité et affinité avec les arcanes.",
        hp = 0, speed = 1.1, jump = 1.12, mana = 30, stamina = 5, damage = 0,
        ability = "Grâce sylvestre", resource = "mana", cost = 20,
    },
}
