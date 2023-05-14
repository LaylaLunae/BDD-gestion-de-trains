import psycopg2
from datetime import date


database = input("A quelle base de données voulez-vous vous connecter ? ")
host = input("Quel est l'host ? ")
user = input("Entrez votre nom d'utilisateur : ")
password = input("Entrez votre mot de passe : ")

# Connect to the PostgreSQL database server
conn = psycopg2.connect(
    host=host,
    database=database,
    user=user,
    password=password
)

cur = conn.cursor()

def check_bdd():
    status = True

    # VIEWS vérifier les contraintes sur les projections

    sql = "SELECT * FROM v_DisposeHotel;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : l'hotel '%s' à l'adresse '%s' n'est relié à aucune gare." % row)
        status = False

    sql = "SELECT * FROM v_DisposeTaxi;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le taxi '%d' n'est relié à aucune gare." % row)
        status = False

    sql = "SELECT * FROM v_DisposeTransportPublic;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le transport public '%d' n'est relié à aucune gare." % row)
        status = False

    sql = "SELECT * FROM v_ArretLigne;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le trajet '%d' doit être relié à au moins 2 gares (actuellement relié à %d gare)." % (row[1], row[0]))
        status = False

    sql = "SELECT * FROM v_Voyage;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : la ligne '%s' doit être reliée à au moins 1 voyage." % row)
        status = False

    sql = "SELECT * FROM v_ConcerneCalendrier;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : la date-exception '%s' (ajout : %s) doit être reliée à au moins 1 calendrier." % row)
        status = False

    sql = "SELECT * FROM v_ArretVoyage;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le voyage '%d' doit être relié à au moins 2 arrêts de ligne (actuellement relié à %d arrêt)." % (row[1], row[0]))
        status = False

    sql = "SELECT * FROM v_ArretVoyage2;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le voyage '%d' est relié à la ligne '%d' mais ce n'est pas le cas d'au moins 1 de ses arrêts." % row)
        status = False

    sql = "SELECT * FROM v_ArretTrajet;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le trajet '%d' doit avoir exactement 2 arrêts (il en a actuellement %s)." % (row[1], row[0]))
        status = False

    sql = "SELECT * FROM v_CompositionBillet;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le billet '%d' n'a pas de trajet." % row)
        status = False

    sql = "SELECT * FROM v_LigneVoyageTypeTrain;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le voyage '%d' est assuré par un %s (train %s), mais sa ligne associée ('%s') est assurée par un %s" % (row[1], row[0], row[3], row[2], row[4]))
        status = False


    #===========================================================================================================
    # CHECK

    # Check date
    # 1er cas:
    # - date complète date_début et date_fin
    # - date => jour vrai
    # - date.except => date = date_except avec ajout false
    #
    # 2e cas:
    # - date=date_except avec ajout true
    #
    sql = "SELECT id_trajet, trajet_date, id_calendrier, date_debut, date_fin, lundi, mardi, mercredi, jeudi, vendredi, samedi, dimanche FROM v_CheckDate WHERE (trajet_date >= date_debut AND trajet_date <= date_fin AND ajout)"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        day = row[1].weekday()
        if not row[day + 5]:
            print("Erreur sur les données dans la base : la date (%s) du trajet '%d' est en contradiction avec le calendrier '%d' (date sur un jour de la semaine non possible)." % (row[1], row[0], row[2]))
            status = False

    sql = "SELECT id_trajet, trajet_date, id_calendrier FROM v_CheckDate WHERE (((trajet_date < date_debut OR trajet_date > date_fin) AND NOT ajout) OR NOT ajout)"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : la date (%s) du trajet '%d' est en contradiction avec le calendrier '%d'." % (row[1], row[0], row[2]))
        status = False

    #  check time
    sql = "SELECT * FROM v_CheckTime;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("Erreur sur les données dans la base : le voyage '%d' est programmé a %s dans le calendrier, mais il part à %s d'après l'arrêt de départ." % (row[2], row[0], row[1]))
        status = False

    # check place
    sql = "SELECT * FROM v_CheckPlace;"
    cur.execute(sql)
    row = cur.fetchone()
    while row:
        if row[0] < row[3]:
            print("Plus de places ont été vendues que le nombre de places dans le train pour le voyage %d du %s." % (row[2], row[1]))
            status = False
        if row[0] == row[3]:
            print("Le train du voyage %d le %s est complet." % (row[2], row[1]))
            status = False
        row = cur.fetchone()

    return status

# INSERT un billet
# if row[0] == row[2]:
#     print("train complet")

# ===========================================================================================================
#
# SELECT requêtes

# Affiche le nombre de trajets par date (SELECT COUNT)
def nb_trajets_par_date():
    sql = "SELECT date_, COUNT(*) AS nombre_trajets FROM Trajet GROUP BY date_;"
    cur.execute(sql)
    rows = cur.fetchall()
    print("Voici le nombre de trajets par date :")
    for row in rows:
        print("\tDate : %s\tNombre de trajets : %s" % (row))

#Affiche le nombre de voyages par ligne de train (SELECT COUNT)
#Elisa
def nb_voyages_par_ligne():
    print("Nombre de voyages par ligne de train :\n")
    sql = "SELECT Ligne.num, COUNT(*) AS nombre_voyages FROM Voyage JOIN Ligne ON Voyage.ligne = Ligne.num GROUP BY Ligne.num;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows :
        print("\nLigne : %s\tNombre de voyages : %i"%(row))

#Affiche l'argent gagné par la société (SELECT SUM) (= total des prix des billets)
#Elisa
def argent_gagne():
    sql = "SELECT SUM(prix) AS somme_prix FROM Billet;"
    cur.execute(sql)
    row = cur.fetchall()
    print("Argent gagné par la société : %f"%(row))

#Affiche la somme des prix des billets par voyageur (SELECT SUM)
#Elisa
def argent_par_voyageur():
    print("Somme des prix des billets par voyageur :\n")
    sql = "SELECT voyageur_nom, voyageur_prenom, voyageur_adresse, SUM(prix) AS somme_prix FROM Billet GROUP BY voyageur_nom, voyageur_prenom, voyageur_adresse;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("\nNom : %s\tPrénom : %s\tAdresse : %s\tArgent dépensé : %f"%(row))

#Afficher le nombre de voyages par jour de la semaine (SELECT CASE)
#Elisa
def nb_voyages_par_jour():
    print("Nombre de voyages par jour de la semaine :\n")
    sql = "SELECT CASE WHEN lundi THEN 'Lundi' WHEN mardi THEN 'Mardi' WHEN mercredi THEN 'Mercredi' WHEN jeudi THEN 'Jeudi' WHEN vendredi THEN 'Vendredi' WHEN samedi THEN 'Samedi' WHEN dimanche THEN 'Dimanche' END AS jour_semaine, COUNT(*) AS nombre_voyages FROM Calendrier JOIN Voyage ON Calendrier.id_calendrier = Voyage.calendrier GROUP BY jour_semaine;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("\nJour : %s\tNombre de voyages : %i"%(row))

#Affiche le nom/prenom/adresse des/du voyageur.s ayant le statut bronze (SELECT WHERE)
#Elisa
def voyageur_bronze():
    print("Voyageurs ayant le statut bronze :\n")
    sql = "SELECT nom, prenom, adresse FROM Voyageur WHERE statut = 'bronze';"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("\nNom : %s\tPrenom : %s\tAdresse : %s"%(row))

#Récupère le taux de remplissage des trains (en %)
#Elisa
def taux_remplissage():
    print("Taux de remplissage des trains :\n")
    sql = "SELECT id_voyage, date_, CAST((nb_billets * 100.0) / nb_places AS numeric(3,2)) AS taux_remplissage FROM v_CheckPlace;"
    cur.execute(sql)
    rows = cur.fetchall()
    for row in rows:
        print("\nNuméro de voyage : %i\tDate : %s\tTaux de remplissage : %f"%(row))

# Création d'un voyageur
#Elisa
def creer_voyageur():
    nom = input("Nom : ")
    prenom = input("Prénom : ")
    adresse = input("Adresse : ")
    tel = input("Téléphone : ")
    paiement = input("Moyen de paiement : ")
    occas = input("Entrez 1 si vous voulez être un voyageur occasionnel, 0 sinon : ")
    
    sql = "SELECT * FROM Voyageur WHERE nom=%s AND prenom=%s AND adresse=%s;"%(nom,prenom,adresse)
    cur.execute(sql)
    rows = cur.fetchall()
    
    if rows :
        print("Vous êtes déjà inscrit.")
    else :
        if occas == 1:
            try :
                sql = "INSERT INTO Voyageur VALUES (%s,%s,%s,%s,%s,NULL,NULL,true);"%(nom,prenom,adresse,tel,paiement)
                cur.execute(sql)
                conn.commit()
            except psycopg2.Error as e:
                print("Erreur : ",e)
        else :
            verif = 0
            while verif == 0 :
                carte = int(input("Numéro de carte"))
                sql = "SELECT carte FROM Voyageur WHERE carte=%i;"%carte
                cur.execute(sql)
                rows = cur.fetchall()
                if not rows :
                    verif = 1
                else :
                    print("Le numéro de carte existe déjà.")
                    print("\n Veuillez en saisir un autre.")
            statut = input("Statut :")
            try :
                sql = "INSERT INTO Voyageur VALUES (%s,%s,%s,%s,%s,%i,%s,false);"%(nom,prenom,adresse,tel,paiement,carte,statut)
                cur.execute(sql)
                conn.commit()
            except psycopg2.Error as e:
                print("Erreur : ",e)

#creerVoyageur- nadia
def creer_compte_voyageur():
    print("----- Création d'un compte voyageur -----")
    nom = input("Nom : ")
    prenom = input("Prénom : ")
    adresse = input("Adresse : ")
    telephone = input("Téléphone : ")
    paiement = input("Méthode de paiement (carte/cheque/monnaie) : ")
    carte = input("Numéro de carte (optionnel) : ")
    statut = input("Statut (bronze/silver/gold/platine) : ")
    occasionnel = input("Voyageur occasionnel ? (oui/non) : ")
    # Conversion 
    occasionnel = True if occasionnel.lower() == "oui" else False
    # Verification Donnees completes
    if not nom or not prenom or not adresse or not telephone or not paiement:
        print("Veuillez fournir toutes les informations nécessaires pour créer le compte voyageur.")
        return
    # Verification si le voyageur existe deja dans la base d
    cursor.execute("SELECT COUNT(*) FROM Voyageur WHERE nom = %s AND prenom = %s AND adresse = %s",
                   (nom, prenom, adresse))
    count = cursor.fetchone()[0]
    if count > 0:
        print("Le voyageur existe déjà dans la base de données.")
        return
    # Insertion du compte voyageur dans la base de données
    try:
        cursor.execute("INSERT INTO Voyageur (nom, prenom, adresse, telephone, paiement, carte, statut, occasionnel) "
                       "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                       (nom, prenom, adresse, telephone, paiement, carte, statut, occasionnel))
        conn.commit()
        print("Le compte voyageur a été créé avec succès.")
    except psycopg2.Error as e:
        print("Une erreur s'est produite lors de la création du compte voyageur :", e)



if check_bdd():

    # MENU

    # Pour le moment, comprend toutes les options dans Menu
    # mais on peut avoir besoin d'en enlever/rassembler
    # (pour-être des sous menus à faire dans les commandes Python)

    print()
    choice = 1
    while choice == 1 or choice == 2:
        print ("Si vous êtes un voyageur, entrez 1")
        print ("Si vous êtes un memebre de la société, entrez 2")
        print ("Pour sortir, entrez autre chose")
        try:
            choice = int(input())
        except ValueError:
            choice = 0
        if choice == 1:
            while choice in range(1, 10):
                print ("Pour créer un compte voyageur, entrez 1")
                print ("Pour acheter un billet, entrez 2")
                print ("Pour consulter la liste des voyages, entrez 3")
                print ("Pour consulter les horaires de trains, entrez 4")
                print ("Pour consulter la liste des voyages, entrez 5")
                print ("Pour chercher trajet en fonction de villes de départ et d'arrivée, entrez 6")
                print ("Pour chercher une date de voyage, entrez 7")
                print ("Pour chercher un trajet en fonction du prix du billet, entrez 8")
                print ("Pour annuler (ou modifier un voyage), entrez 9")
                print ("Pour revenir en arrière, entrez 10")
                print ("Pour sortir, entrez autre chose")
                try:
                    choice = int(input())
                except ValueError:
                    choice = 0
                if choice == 1:
                    print()
                    print("Fonction Python 1")
                    print()
                if choice == 2:
                    print()
                    print("Fonction Python 2")
                    print()
                if choice == 3:
                    print()
                    print("Fonction Python 3")
                    print()
                if choice == 4:
                    print()
                    print("Fonction Python 4")
                    print()
                if choice == 5:
                    print()
                    print("Fonction Python 5")
                    print()
                if choice == 6:
                    print()
                    print("Fonction Python 6")
                    print()
                if choice == 7:
                    print()
                    print("Fonction Python 7")
                    print()
                if choice == 8:
                    print()
                    print("Fonction Python 8")
                    print()
                if choice == 9:
                    print()
                    print("Fonction Python 9")
                    print()
                if choice == 10:
                    choice = 1
                    print()
                    break
        if choice == 2:
            while choice in range(1, 8):
                print ("Pour gérer les voyages, entrez 1")
                print ("Pour créer un calendrier, entrez 2")
                print ("Pour gérer les gares, entrez 3")
                print ("Pour gérer les trains, entrez 4")
                print ("Pour gérer les lignes, entrez 5")
                print ("Pour obtenir des statistiques sur la société, entrez 6")
                print ("Pour revenir en arrière, entrez 7")
                print ("Pour sortir, entrez autre chose")
                try:
                    choice = int(input())
                except ValueError:
                    choice = 0
                if choice == 1:
                    print()
                    print("Fonction Python 1")
                    creerVoyageur()
                    print()
                if choice == 2:
                    print()
                    print("Fonction Python 2")
                    print()
                if choice == 3:
                    print()
                    print("Fonction Python 3")
                    print()
                if choice == 4:
                    print()
                    print("Fonction Python 4")
                    print()
                if choice == 5:
                    print()
                    print("Fonction Python 5")
                    print()
                if choice == 6:
                    print()
                    nb_trajets_par_date()
                    print()
                if choice == 7:
                    choice = 1
                    print()
                    break

    print("Au revoir")

conn.close()
