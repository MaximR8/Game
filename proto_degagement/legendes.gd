class_name Legendes

# ─────────────────────────────────────────────────────────────
# LES LÉGENDES (27/09) — ce que raconte le dos d'une carte (dos_info.gd) : d'où vient le
# personnage, ce qu'on dit de lui. Deux ou trois phrases, tirées du vrai folklore.
# Saint Georges : d'après la Légende dorée, telle que la raconte la Ville de Mons (lien donné par Maxim,
# 28/09 : mons.be, « Doudou › Ducasse rituelle › La légende dorée »).
# 🔴 Pas de lettres en exposant (« XVIᵉ », « 1ʳᵉ ») : Castoro ne les a pas, elles sortent en boîte.
# Maxim les relit dans le jeu. Une carte sans légende n'en montre pas (rien d'inventé).
# ─────────────────────────────────────────────────────────────

const TEXTES := {
	"doudou": "Le dragon du Doudou de Mons. Chaque dimanche de la Trinité, sur la Grand-Place, Saint Georges le combat au Lumeçon sous les cris de la foule. Arracher un crin de sa queue porte bonheur toute l'année.",
	"thor": "Dieu du tonnerre des Scandinaves, fils d'Odin. Son marteau Mjöllnir revient toujours dans sa main après avoir frappé. Quand l'orage gronde, c'est Thor qui passe sur son char tiré par deux boucs.",
	"bahamut": "Dans les récits arabes, Bahamut est le poisson colossal qui porte le monde : sur son dos, un taureau ; sur le taureau, un rocher ; sur le rocher, un ange qui tient la Terre. Sous lui, rien que l'eau et les ténèbres.",
	"nian": "Chaque Nouvel An, la bête Nian descendait des montagnes dévorer les récoltes et les villageois. On découvrit qu'elle craignait le rouge, le feu et le bruit : depuis, la Chine fête le réveillon avec des lanternes rouges et des pétards.",
	"kitsune": "Au Japon, la renarde kitsune gagne une queue tous les cent ans. Rusée, messagère de la déesse Inari, elle sait prendre forme humaine. À neuf queues, on dit qu'elle voit et entend tout ce qui se passe dans le monde.",
	"loki": "Dieu de la ruse chez les Scandinaves, ni tout à fait ami ni tout à fait ennemi des dieux. Il change de forme à volonté : saumon, jument, mouche. Au Ragnarök, la fin du monde, il se range du côté des géants.",
	"wukong": "Né d'un œuf de pierre au sommet d'une montagne, le Roi des Singes apprit les soixante-douze métamorphoses et vola les pêches d'immortalité. Il défia le Ciel tout entier, jusqu'à ce que Bouddha l'enferme sous une montagne pour cinq cents ans.",
	"korrigan": "Petits êtres des landes bretonnes, les korrigans dansent la nuit autour des dolmens. Qui entre dans leur ronde doit danser jusqu'à l'aube ; qui leur rend service repart parfois les poches pleines d'or.",
	"georges": "Selon la Légende dorée, Georges, tribun de l'armée romaine venu de Cappadoce, arriva à Silène, en Libye, où un dragon exigeait chaque jour deux brebis, puis des victimes tirées au sort. Quand le sort désigna la fille du roi, il chargea le monstre et le blessa gravement ; la princesse lui passa sa ceinture autour du cou.",
	"ifrit": "Dans les contes arabes, l'ifrit est un djinn de feu, puissant et redouté, qui hante les ruines et les profondeurs. Qui en enferme un dans une lampe ou un anneau peut le forcer à le servir.",
	"anansi": "L'araignée Anansi, des contes akans du Ghana, est la plus rusée des créatures. Elle acheta au dieu du ciel toutes les histoires du monde en lui livrant quatre créatures qu'on disait imprenables. Depuis, chaque conte lui appartient.",
	"cerbere": "Le chien à trois têtes qui garde la porte des Enfers grecs : il laisse entrer les morts, mais n'en laisse sortir aucun. Seul Héraclès parvint à le dompter, à mains nues.",
	"golem": "À Prague, au XVIe siècle, le rabbin Loew modela un géant d'argile pour protéger les siens. Le mot « emet », vérité, l'animait ; effacer une lettre en faisait « met », mort, et le Golem redevenait poussière.",
	"fenrir": "Le loup géant, fils de Loki, grandit si vite que les dieux prirent peur. Ils l'enchaînèrent avec Gleipnir, un lien tissé du bruit des pas d'un chat et de la barbe d'une femme. Au Ragnarök, il brisera ses chaînes.",
	"roc": "Un oiseau si immense qu'il emporte des éléphants dans ses serres pour nourrir ses petits. Sindbad le marin, abandonné sur une île, s'attacha à sa patte pour s'en échapper.",
	"quetzalcoatl": "Le Serpent à plumes des Aztèques, dieu du vent, du savoir et de l'étoile du matin. On raconte qu'il offrit le maïs aux hommes, puis partit vers l'est sur un radeau de serpents en promettant de revenir.",
	"kelpie": "Dans les lochs d'Écosse, le kelpie prend l'apparence d'un beau cheval qui se laisse approcher. Qui monte sur son dos y reste collé, et le cheval plonge au fond de l'eau. Seule une bride magique peut le dompter.",
	"banshee": "En Irlande, la banshee, la « femme des fées », pleure la nuit sous les fenêtres d'une famille : ses cris annoncent qu'un des siens va bientôt mourir. On la dit vêtue de blanc, peignant ses longs cheveux d'un peigne d'argent.",
	"mothman": "En 1966 et 1967, à Point Pleasant, en Virginie-Occidentale, des dizaines de témoins virent une créature ailée aux yeux rouges. Peu après, le pont de la ville s'effondra : depuis, on le tient pour un présage de malheur.",
	"chevalier": "Le Dullahan d'Irlande chevauche la nuit, sa propre tête sous le bras. Là où il s'arrête, quelqu'un meurt. Rien ne l'arrête, ni porte ni serrure : seul l'or l'effraie.",
	"babayaga": "La sorcière des forêts russes vit dans une isba montée sur des pattes de poulet, et vole dans un mortier en effaçant ses traces d'un coup de balai. Elle dévore les imprudents… mais aide parfois ceux qui la respectent.",
	"wendigo": "Chez les peuples algonquiens, le wendigo est l'esprit de l'hiver et de la faim. Squelettique, le cœur de glace, il n'est jamais rassasié : plus il mange, plus il grandit, et plus il a faim.",
	"minotaure": "Mi-homme, mi-taureau, il était enfermé par le roi Minos dans le Labyrinthe de Crète, et Athènes devait lui livrer des jeunes gens. Thésée le tua, puis retrouva la sortie grâce au fil d'Ariane.",
	"cuelebre": "Dans les grottes des Asturies, le cuélebre, un serpent ailé, garde des trésors et des fées enchantées, les xanas. Avec l'âge, ses écailles deviennent si dures qu'aucune arme ne les perce : il faut viser sa gorge.",
	"thunderbird": "Pour de nombreux peuples d'Amérique du Nord, l'Oiseau-Tonnerre est un esprit géant : ses battements d'ailes font gronder le tonnerre, et l'éclair jaillit de ses yeux. Il combat les serpents des eaux.",
	"anubis": "Le dieu à tête de chacal de l'Égypte ancienne guide les morts. Dans la salle du jugement, il pèse leur cœur face à la plume de Maât : trop lourd de fautes, le cœur est dévoré par Ammit.",
	"yeti": "Les Sherpas de l'Himalaya parlent d'une créature couverte de poils qui marche debout dans les neiges éternelles. En 1951, des alpinistes photographièrent d'immenses empreintes : on cherche encore l'abominable homme des neiges.",
	"chupacabra": "Apparu à Porto Rico en 1995, puis au Mexique, le chupacabra, le « suceur de chèvres », attaquerait le bétail la nuit pour en boire le sang. Personne ne l'a jamais capturé.",
	"tikbalang": "Aux Philippines, le tikbalang, mi-homme mi-cheval, égare les voyageurs dans la forêt. Pour retrouver son chemin, on retourne sa chemise. Qui arrache le crin d'or de sa crinière en fait son serviteur.",
	"bunyip": "Dans les marais et les billabongs d'Australie, le bunyip guette la nuit. Les Aborigènes racontent ses cris qui résonnent sur l'eau : il entraîne au fond ceux qui s'approchent trop près.",
	"troll": "Géants des montagnes de Norvège, les trolls vivent dans les forêts et sous les ponts. Ils ne sortent que la nuit : un seul rayon de soleil les change en pierre, d'où les rochers aux formes étranges des fjords.",
	# Les sbires (27/09)
	"chinchin": "Au Lumeçon de Mons, les Chinchins, montés sur leurs chevaux d'osier, forment la garde de Saint Georges. Ils encaissent les coups du dragon pour que leur chevalier puisse frapper.",
	"hommefeuilles": "Couverts de lierre de la tête aux pieds, les Hommes de feuilles sont les alliés du dragon au Lumeçon de Mons : ils le défendent contre Saint Georges et ses Chinchins.",
	"diable": "Vêtus de noir et de rouge, les Diables du Lumeçon se rangent du côté du dragon. Pendant le combat, ils harcèlent les Chinchins et taquinent la foule.",
	"esprit_foudre": "Dans bien des légendes, l'orage a ses esprits : ils naissent de l'éclair et vivent dans les nuées. Quand le tonnerre roule sur les montagnes, on dit qu'ils rient.",
	"esprit_eau": "Les esprits des sources et des cascades hantent les eaux claires de toutes les légendes. Ils guérissent qui les respecte, et noient qui salit leur rivière.",
	"esprit_feu": "Né des braises d'un volcan, l'esprit du feu danse là où la roche fond. Les forgerons lui laissaient une offrande, pour que leur foyer ne s'éteigne jamais.",
	"esprit_sylvestre": "Les esprits des forêts veillent sur les arbres anciens. Qui abat un vieux chêne sans leur demander la permission risque de ne jamais retrouver son chemin.",
	"esprit_roche": "Les montagnes ont leurs gardiens de pierre : ils dorment des siècles sous la mousse, et se lèvent quand on trouble la vallée.",
	"follet": "Petite flamme des marais, le feu follet danse la nuit au-dessus de l'eau. Qui le suit s'égare dans la tourbe : on dit que ce sont des âmes errantes.",
}


static func de(id: String) -> String:
	return str(TEXTES.get(id, ""))
