---------------------------------------------------
-- MacroForge — Locale: French
---------------------------------------------------
local L = LibStub("AceLocale-3.0"):NewLocale("MacroForge", "frFR")
if not L then return end

-- General
L["ADDON_LOADED"] = "MacroForge v%s - %s"
L["UNKNOWN_CMD"] = "Inconnu: %s - /mf help"
L["OPEN_MACRO_FIRST"] = "Ouvrez une macro d'abord pour voir son historique."

-- Settings headers
L["GENERAL"] = "General"
L["EDITOR"] = "Editeur"
L["BACKUPS"] = "Sauvegardes"
L["DATA"] = "Donnees"

-- Settings labels
L["OPT_AUTOSWAP"] = "Auto-swap profils au changement de specialisation"
L["OPT_AUTOCOMPLETE"] = "Auto-completion dans l'editeur (sorts, commandes, conditions)"
L["OPT_SYNTAX_COLORS"] = "Coloration syntaxique dans l'editeur"
L["OPT_AUTOSAVE_DRAFT"] = "Sauvegarde automatique des brouillons"
L["OPT_SOUND"] = "Effets sonores (sauvegarde, undo/redo...)"
L["OPT_MINIMAP"] = "Afficher le bouton minimap"
L["OPT_FONTSIZE"] = "Taille de la police editeur"
L["OPT_FONT"] = "Police de l'editeur"
L["OPT_MAX_BACKUPS"] = "Nombre maximum de backups"
L["OPT_MAX_HISTORY"] = "Nombre de versions dans l'historique"

-- Profiles
L["PROFILE_SAVED"] = "Profil sauvegarde"
L["PROFILE_LOADED"] = "Profil charge"
L["PROFILE_NO_SPEC"] = "Impossible de detecter la spe."
L["PROFILE_NONE"] = "Aucun profil pour %s. Utilise /mf save."
L["PROFILE_AUTOSWAP"] = "Auto-swap"
L["AUTOSWAP_ON"] = "Auto-swap: active"
L["AUTOSWAP_OFF"] = "Auto-swap: desactive"
L["NO_MACROS_TO_LOAD"] = "Aucune macro a charger."

-- Backup
L["BACKUP_CREATED"] = "Backup cree"
L["BACKUP_RESTORED"] = "Backup restaure du %s"
L["BACKUP_NOT_FOUND"] = "Backup #%d non trouve."

-- Macros
L["MACRO_CREATED"] = "Macro creee: %s"
L["MACRO_DELETED"] = "Macro supprimee: %s"
L["MACRO_LIMIT_CHAR"] = "Limite atteinte: %d/18 macros perso."
L["MACRO_LIMIT_ACCOUNT"] = "Limite atteinte: %d/120 macros compte."
L["MACROS_PERSO"] = "perso"
L["MACROS_COMPTE"] = "compte"
L["PERSO_TAB"] = "Perso (%d/18)"
L["COMPTE_TAB"] = "Compte (%d/120)"

-- UI
L["NO_MACRO"] = "Aucune macro."
L["SEARCH"] = "Rechercher"
L["CLEAR"] = "Vider"
L["CREATE"] = "Creer"
L["IMPORT"] = "Importer"
L["EDIT"] = "Editer"
L["DUPLICATE"] = "Dupliquer"
L["EXPORT"] = "Exporter"
L["DRAG_ACTIONBAR"] = "Glisser en barre d'action"
L["DELETE"] = "Supprimer"

-- Editor
L["MACRO_NAME_LABEL"] = "Nom de la macro (max 16 caracteres)"
L["MACRO_BODY_LABEL"] = "Corps de la macro (max 255 caracteres)"
L["SAVE"] = "Sauvegarder"
L["COPY"] = "Copier"
L["CANCEL"] = "Annuler"
L["SHORTEN"] = "Raccourcir"
L["INSERT_SPELL"] = "+ Inserer sort"
L["INSERT_SNIPPET"] = "Inserer un snippet..."
L["NEW_MACRO"] = "+ Nouvelle macro"
L["SAVE_FIRST_DRAG"] = "Sauvegardez d'abord avant de glisser."
L["SAVED"] = "Sauvegarde!"
L["SAVED_DETAIL"] = "%s sauvegardee (%d/255 caracteres)"
L["SHORTENED"] = "Raccourci: %d caractere(s) economise(s)"
L["ALREADY_OPTIMIZED"] = "Deja optimise."
L["DRAFT_RESTORED"] = "Brouillon restaure!"
L["DRAFT_DIALOG"] = "|cff00ccffMacroForge|r\n\nUn brouillon non-sauvegarde a ete trouve.\nRestaurer?"
L["RESTORE"] = "Restaurer"
L["IGNORE"] = "Ignorer"

-- History
L["HISTORY"] = "Historique"
L["NO_HISTORY"] = "Aucun historique pour cette macro."
L["VERSION_RESTORED"] = "Version #%d restauree!"
L["CHARS"] = "%d/255 caracteres"

-- Share
L["SHARE"] = "Partager"
L["SHARE_EXPORT_TITLE"] = "Partager"
L["SHARE_IMPORT_TITLE"] = "Importer (partage)"
L["SHARE_COPY_HELP"] = "Copiez le code ci-dessous et envoyez-le a un ami."
L["SHARE_IMPORT_HELP"] = "Il pourra l'importer avec /mf import ou le bouton Importer."
L["SHARE_PASTE_HELP"] = "Collez un code MF7: recu d'un autre joueur."
L["SHARE_CODE_LABEL"] = "Code de partage:"
L["SHARE_OPEN_EDITOR"] = "Ouvrir dans l'editeur"
L["SHARE_CREATE_DIRECT"] = "Creer directement"
L["SHARE_NO_DECODED"] = "Aucune macro decodee."
L["SHARE_IMPORTED"] = "Macro importee: %s"
L["SHARE_INVALID"] = "Format invalide"
L["SHARE_NOT_MF"] = "Format invalide (pas un code MacroForge)"
L["SHARE_DECODE_FAIL"] = "Decodage echoue"
L["SHARE_BAD_STRUCT"] = "Structure invalide"
L["SHARE_PREVIEW"] = "(collez un code ci-dessus)"

-- Share - direct send via AceComm
L["SEND_MACRO"] = "Envoyer la macro"
L["SEND_TARGET"] = "Nom du joueur cible:"
L["SEND_SUCCESS"] = "Macro envoyee a %s!"
L["SEND_NO_TARGET"] = "Entrez un nom de joueur."
L["RECV_MACRO"] = "Macro recue de %s: %s"
L["RECV_ACCEPT"] = "Accepter"
L["RECV_DECLINE"] = "Refuser"
L["RECV_DIALOG"] = "|cff00ccffMacroForge|r\n\n%s vous a envoye une macro:\n|cffffff00%s|r\n\nAccepter?"

-- Duplicates
L["DUPLICATES"] = "Doublons"
L["DETECT_DUPLICATES"] = "Detecter les doublons"
L["NO_DUPLICATES"] = "Aucun doublon trouve."

-- Templates
L["TEMPLATES"] = "Templates"

-- Builder
L["BUILDER"] = "Condition Builder"

-- Commands
L["COMMANDS"] = "Palette de commandes"

-- Tools
L["TOOLS"] = "Outils"
L["TOOLS_BUILDER_DESC"] = "Construire visuellement des conditions [mod:shift, @focus, harm...]"
L["TOOLS_TEMPLATES_DESC"] = "Macros pretes a l'emploi classees par role et specialisation"
L["TOOLS_HISTORY_DESC"] = "Voir et restaurer les versions precedentes de cette macro"
L["TOOLS_DUPES_DESC"] = "Scanner toutes vos macros pour trouver les duplicatas"

-- Analysis
L["ANALYSIS_HEADING"] = "Analyse & Explication"
L["ANALYSIS_HINT"] = "Analyse en temps reel. Survolez pour voir les tooltips des sorts."
L["SPELLS_HEADING"] = "Sorts & Objets detectes"
L["SPELLS_HINT"] = "Survolez une icone pour voir le tooltip Blizzard du sort ou de l'objet."

-- File section
L["FILE"] = "Fichier"
L["DRAG"] = "Glisser en barre"
L["COPY_MACRO"] = "Copier la macro"
L["COPY_HELP"] = "Ctrl+C pour copier, puis collez ou vous voulez."
L["IMPORT_MACRO"] = "Importer une macro"
L["PASTE_HERE"] = "Collez le texte de la macro ici:"
L["IMPORT_SUCCESS"] = "Macro importee!"
L["EXPORT_MACRO"] = "Exporter la macro"
L["COPY_BELOW"] = "Copiez le texte ci-dessous:"

-- Settings data
L["MACROS_COUNT"] = "Macros: %d/18 perso, %d/120 compte"
L["PROFILES_COUNT"] = "Profils: %d — Backups: %d"
L["PURGE_HISTORY"] = "Purger historique"
L["PURGE_DRAFTS"] = "Purger brouillons"
L["HISTORY_PURGED"] = "Historique purge."
L["DRAFTS_PURGED"] = "Brouillons purges."

-- Minimap
L["MINIMAP_LEFT"] = "Clic gauche"
L["MINIMAP_RIGHT"] = "Clic droit"
L["MINIMAP_OPEN"] = "Ouvrir"
L["MINIMAP_HELP"] = "Aide"

-- Keybindings
L["BINDING_TOGGLE"] = "Ouvrir/Fermer MacroForge"
L["BINDING_BUILDER"] = "Condition Builder"
L["BINDING_COMMANDS"] = "Palette de commandes"

-- Slash help
L["HELP_TITLE"] = "=== MacroForge v%s ==="
L["HELP_SHOW"] = "Ouvrir/fermer"
L["HELP_SAVE"] = "Sauvegarder profil"
L["HELP_LOAD"] = "Charger profil"
L["HELP_BACKUP"] = "Backup"
L["HELP_RESTORE"] = "Restaurer"
L["HELP_AUTOSWAP"] = "Toggle auto-swap"
L["HELP_ANALYZE"] = "Analyser macros"
L["HELP_BUILDER"] = "Condition Builder"
L["HELP_COMMANDS"] = "Palette commandes/sorts"
L["HELP_TEMPLATES"] = "Parcourir templates"
L["HELP_SHARE"] = "Partager / importer macro"
L["HELP_IMPORT"] = "Importer un code partage"
L["HELP_EXPORT"] = "Exporter macro"
L["HELP_DUPLICATES"] = "Detecter les doublons"
L["HELP_HISTORY"] = "Historique de la macro courante"
L["HELP_SETTINGS"] = "Parametres de l'addon"
L["HELP_SHORTCUTS"] = "Raccourcis: Ctrl+S sauvegarder, Ctrl+Z undo, Ctrl+Y redo"

-- Click tooltips
L["CLICK_EDIT"] = "|cff00ccffClic|r editer"
L["CLICK_SHIFT_DRAG"] = "|cffff9933Shift+Clic|r glisser"
L["CLICK_RIGHT_MENU"] = "|cff888888Clic-droit|r menu"
L["QUALITY"] = "Qualite: %d%% (syntaxe, sorts, longueur)"

-- Editor UI
L["EDITOR_TITLE"] = "Editeur"
L["TOOLS_HEADING"] = "Outils"
L["CONDITION_BUILDER"] = "Condition Builder"
L["CONDITION_BUILDER_DESC"] = "Construire visuellement des conditions [mod:shift, @focus, harm...]"
L["TEMPLATES_BTN"] = "Templates"
L["TEMPLATES_DESC"] = "Macros pretes a l'emploi classees par role et specialisation"
L["HISTORY_BTN"] = "Historique"
L["HISTORY_DESC"] = "Voir et restaurer les versions precedentes de cette macro"
L["DETECT_DUPES_BTN"] = "Detecter doublons"
L["DETECT_DUPES_DESC"] = "Scanner toutes vos macros pour trouver les duplicatas"
L["INSERT_SNIPPET_LABEL"] = "Inserer un snippet..."
L["FONT_SIZE"] = "Taille police"
L["FILE_HEADING"] = "Fichier"
L["ANALYSIS_LIVE_HINT"] = "Analyse en temps reel. Survolez pour voir les tooltips des sorts."
L["SPELL_ICON_HINT"] = "Survolez une icone pour voir le tooltip Blizzard du sort ou de l'objet."
L["EMPTY_NAME"] = "Nom vide!"
L["MISSING_INDEX"] = "Index manquant!"
L["NOTHING_TO_UNDO"] = "Rien a annuler."
L["NOTHING_TO_REDO"] = "Rien a refaire."
L["SAVE_FIRST"] = "Sauvegardez d'abord."
L["DRAG_SAVE_FIRST"] = "Sauvegardez d'abord avant de glisser."
L["COPY_MACRO_TITLE"] = "Copier la macro"
L["COPY_HELP_MSG"] = "Ctrl+C pour copier, puis collez ou vous voulez."
L["MACRO_IMPORTED"] = "Macro importee!"
L["COPY_BELOW_MSG"] = "Copiez le texte ci-dessous:"
L["ALREADY_OPTIMIZED"] = "Deja optimise."
L["SHORTENED_MSG"] = "Raccourci: %d caractere(s) economise(s)"
L["DRAFT_FOUND"] = "|cff00ccffMacroForge|r\n\nUn brouillon non-sauvegarde a ete trouve.\nRestaurer?"
L["DRAFT_RESTORED_MSG"] = "Brouillon restaure!"
L["SLOT_N"] = "Slot %d"
L["SLOT_LABEL"] = "Slot"
L["CHARACTER_SCOPE"] = "Perso"
L["ACCOUNT_SCOPE"] = "Compte"
L["NEW_MACRO_TITLE"] = "+ Nouvelle macro"
L["SAVE_BTN"] = "Sauvegarder"
L["COPY_BTN"] = "Copier"
L["IMPORT_BTN"] = "Importer"
L["EXPORT_BTN"] = "Exporter"
L["CANCEL_BTN"] = "Annuler"
L["SHORTEN_BTN"] = "Raccourcir"
L["INSERT_SPELL_BTN"] = "+ Inserer sort"
L["DRAG_TO_BAR_BTN"] = "Glisser en barre"
L["RESTORE_BTN"] = "Restaurer"
L["IGNORE_BTN"] = "Ignorer"
L["DETECTED_SPELLS_HEADING"] = "Sorts & Objets detectes"
L["IMPORT_MACRO_TITLE"] = "Importer une macro"
L["EXPORT_MACRO_TITLE"] = "Exporter la macro"
L["PASTE_MACRO_TEXT_LABEL"] = "Collez le texte de la macro ici:"
L["COPY_BELOW_LABEL"] = "Copiez le texte ci-dessous:"
L["MACRO_SAVED"] = "Sauvegarde: %s"
L["MACRO_BODY_LABEL_COUNT"] = "|cffffff99Corps de la macro|r  %s%d/255|r"
L["AND_MORE_ISSUES"] = "... et %d de plus"
L["FIX_SUGGESTION"] = "-> %s"
L["CHECK_GRIMOIRE_HINT"] = "(verifier grimoire)"
L["DUPLICATE_DETECTOR_BTN"] = "Detecter doublons"
L["DUPLICATE_DETECTOR_DESC"] = "Scanner toutes vos macros pour trouver les duplicatas"

-- Delete confirmation
L["DELETE_CONFIRM"] = "|cff00ccffMacroForge|r\n\nSupprimer la macro |cffffff00%s|r ?\nCette action est irreversible."
L["DELETE_YES"] = "Supprimer"
L["DELETE_NO"] = "Annuler"
L["RESET"] = "Reinitialiser"

-- Builder
L["BUILDER_TITLE"] = "Condition Builder"
L["BUILDER_HEADING"] = "Compositeur de conditions"
L["BUILDER_TARGET_LABEL"] = "Cible (@target)"
L["BUILDER_CONDITIONS_LABEL"] = "Conditions"
L["BUILDER_INSERT"] = "Inserer dans l'editeur"
L["BUILDER_PREVIEW"] = "Apercu"
L["BUILDER_EMPTY"] = "(vide)"

-- IconPicker
L["ICON_PICKER_TITLE"] = "Icones"
L["ICON_SEARCH"] = "Rechercher"
L["ICON_CLICK_SELECT"] = "Clic pour selectionner"
L["ICON_NONE_FOUND"] = "Aucune icone trouvee."

-- SlashDB categories
L["CAT_COMBAT"] = "Combat"
L["CAT_TARGET"] = "Ciblage"
L["CAT_PET"] = "Familier"
L["CAT_CHAT"] = "Chat"
L["CAT_CHAR"] = "Personnage"
L["CAT_GUILD"] = "Guilde"
L["CAT_PARTY"] = "Groupe/Raid"
L["CAT_SYSTEM"] = "Systeme"
L["CAT_PVP"] = "PvP"
L["CAT_BATTLEPET"] = "Mascotte"
L["CAT_UI"] = "Interface"

-- DuplicateDetector
L["DUPES_TITLE"] = "Doublons detectes"
L["DUPES_NONE"] = "Aucun doublon! Toutes vos macros sont uniques."
L["DUPES_GROUPS"] = "%d groupe(s) de doublons trouves (%d macros en trop)"
L["DUPES_GROUP_N"] = "Groupe %d"
L["DUPES_IDENTICAL"] = "%d macros identiques"
L["DUPES_KEEP"] = "(garder)"
L["DUPES_DELETED"] = "Supprime: %s"

-- CommandPalette
L["PALETTE_TITLE"] = "Commandes & Sorts"
L["PALETTE_SEARCH_LABEL"] = "Rechercher (commande ou sort)"
L["PALETTE_SEARCH_HINT"] = "Tapez / pour filtrer les commandes, ou un nom de sort/objet."
L["PALETTE_SLASH_HEADING"] = "Commandes Slash"
L["PALETTE_SPELL_HEADING"] = "Sorts / Objets"
L["PALETTE_NO_RESULT"] = "Aucun resultat pour: %s"
L["PALETTE_CATEGORY"] = "Categorie: %s"
L["PALETTE_CLICK_INSERT"] = "Clic pour inserer"
L["PALETTE_TITLE_SPELLS"] = "Sorts & Objets"
L["PALETTE_TITLE_COMMANDS"] = "Commandes Slash"
L["INSERT_CMD_BTN"] = "+ Inserer commande"
