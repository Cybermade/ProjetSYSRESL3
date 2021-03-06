#!/bin/bash
Init_Fichiers()
{
    >>classement.joueurs
    if [ `awk 'BEGIN{a=0}{a++}END{print a}' classement.joueurs` == 0 ]; then
        echo "TOP10 Joueurs/rounds" >> classement.joueurs
    fi
    >cartes.melangees 
    touch cartes.distruibuees.round
    >cartes.distruibuees.round
    touch inscrit.noms
    >inscrit.noms #On va garder les Nom / PID par joueur
    touch gestion.jeu.pid
    >gestion.jeu.pid
    touch round.en.cours
    >round.en.cours
    touch toutes.les.cartes.posees
    >toutes.les.cartes.posees

}



Init_Jeu()
{
    echo "Bienvenue dans the mind"
    echo "Combien de joueurs voulez vous?"
    
    Init_Fichiers
    nbRound=1
    echo $$ > gestion.jeu.pid
    inscrit=0
    read nbJoueurs
    echo "En attente de l'inscription des joueurs..."
    NBCartesJouees=0
    trap 'arrayNames[$inscrit]=`awk -v ainscrit=$inscrit '"'"'NR==ainscrit+1{print $1}'"'"' inscrit.noms`;
    pidNames[inscrit]=`awk -v ainscrit=$inscrit '"'"'NR==ainscrit+1{print $2}'"'"' inscrit.noms`;
    echo "Joueur inscrit : ${arrayNames[$inscrit]} / PID ${pidNames[inscrit]} / TInscrit $((inscrit+1))";
    ((inscrit=inscrit+1))' USR1
    while [ "$inscrit" -ne "$nbJoueurs" ] 
    do
        :
    done
}

Distribuer_Cartes()
{
nb_cartes_a_distribuer=0
nb_joueur=0 

while [ $nb_joueur -lt $nbJoueurs ]
do
    nb_cartes_a_distribuer=0
    cartes=""
    #Servir les cartes aux joueurs
    while [ $nb_cartes_a_distribuer -lt $nbRound ]
    do
        cartes="$cartes `awk -v var=$NBCartesJouees '(NR==var+1) {print}' cartes.melangees`"
        ((NBCartesJouees=NBCartesJouees+1))
        ((nb_cartes_a_distribuer=nb_cartes_a_distribuer+1))
    done
    echo "${arrayNames[$nb_joueur]} ${pidNames[$nb_joueur]} $cartes">>cartes.distruibuees.round
    ((nb_joueur=nb_joueur+1))
done
nb_joueur=0 
#Envoyer un signal aux joueurs pour leurs dire que vous pouvez recuprer vos cartes
while [ $nb_joueur -lt $nbJoueurs ]
do
kill -s USR1 `awk -v var=$nb_joueur '(NR==var+1){print $2}' inscrit.noms`
((nb_joueur=nb_joueur+1))
done
}
Random_Melange()
{   
    #On m??lange les cartes
    while [ `awk 'END{print NR}' cartes.melangees` -lt 100 ]
    do
        RandomCarte=$((1 + $RANDOM % 100))
        #Si la carte prise a d??j?? ??t?? prise on reprend
        while [ `awk -v var=$RandomCarte 'BEGIN{count = 0}($1==var) {count++} END { print count }' cartes.melangees` -ne 0 ]
        do
        RandomCarte=$((1 + $RANDOM % 100))
        done
        echo $RandomCarte>>cartes.melangees
    done

    
}
Carte_Posee()
{   #Rajouter la derni??re carte pos??e dans la liste de toutes les cartes posees
    awk 'END{print $0}' round.en.cours >> toutes.les.cartes.posees
    #Afficher toutes les cartes posees par round
    #clear;printf "Cartes Jou??es en tout :";awk '{printf "%s"" ",$0}END{printf "\n"}' toutes.les.cartes.posees
    clear;echo "Cartes Jou??es en tout :";awk '{print}END{printf "\n"}' toutes.les.cartes.posees
    nb_joueur=0
    #Envoyer un signal ?? tous les joueurs pour leurs indiquer qu'une carte a ??t?? pos??e
    while [ $nb_joueur -lt $nbJoueurs ]
    do
        kill -s USR2 `awk -v var=$nb_joueur '(NR==var+1){print $2}' inscrit.noms`
        ((nb_joueur=nb_joueur+1))
    done
    #Fin du round si toutes les cartes du round ont ??t?? pos??es
    #Ou Si toutes les cartes ont ??t?? pos??es (les 100 cartes)
    #On doit faire la double v??rification au cas ou ?? la fin un joueur
    #ne recoit pas le m??me nombre de carte que les autres
    #au cas ou il ny ai plus...
    if [ `awk 'END{print NR}' round.en.cours` == $(($nbRound*$nbJoueurs)) ] || \
    [ `awk 'BEGIN{a=0}/[0-9]/{a++}END{print a}' toutes.les.cartes.posees` == 100 ]
    then
        a=`awk 'BEGIN{a=0}/[0-9]/{a++}END{print a}' toutes.les.cartes.posees`
        echo "R : $nbRound, C : $a"
        Verifier_Si_Round_Gagne
    fi

}
Verifier_Si_Round_Gagne()
{
    i=2
    #Verifier si toutes les cartes posees durant le round sont par ordre croissant
    while [ ! $i -gt `awk 'END{print NR}' round.en.cours` ]
    do
        if [ `awk -v var=$i '(NR==var-1){print $2}' round.en.cours` -gt `awk -v var=$i '(NR==var){print $2}' round.en.cours` ]
            then
            Etablir_Classement
            echo "Perdu...Renitialisation"
            echo "Perdu...Renitialisation">toutes.les.cartes.posees
            echo "Perdu...Renitialisation">round.en.cours
            nb_joueur=0
            #Envoyer un signal ?? tous les joueurs pour leur dire que c'est perdu
            while [ $nb_joueur -lt $nbJoueurs ]
                do
                    kill -s USR2 `awk -v var=$nb_joueur '(NR==var+1){print $2}' inscrit.noms`
                    ((nb_joueur=nb_joueur+1))
                done
            #Rejouer ou pas?
            echo "Voulez vous rejouer ? (O/N)"
            read decision
            while [ $decision != "N" ] && [ $decision != "O" ]
                do
                echo "Voulez vous rejouer ? (O/N)"
                read decision
                done
            #Si on rejoue pas
            if [ $decision == "N" ]
                then
                En_JEU=false
            #Si on rejoue
            else
                nbRound=1
                NBCartesJouees=0
                >round.en.cours
                >toutes.les.cartes.posees
                >cartes.distruibuees.round
                >cartes.melangees
                Random_Melange
                Distribuer_Cartes
            fi


            return 0
        fi
    ((i=i+1))
    done
    #Si toutes les cartes ont pas ??t?? pos??es(on reste en jeu)
    if [ $NBCartesJouees -lt 100 ]
    then
        ((nbRound=nbRound+1))
        >round.en.cours
        >cartes.distruibuees.round
        echo "//">>toutes.les.cartes.posees
        Distribuer_Cartes
    #Sinon gagn??
    else 
        echo "Gagn??"
        echo "Gagn??">toutes.les.cartes.posees
        echo "Gagn??">round.en.cours
            nb_joueur=0
            #Envoyer un signal ?? tous les joueurs pour leur dire que c'est gagn??
            while [ $nb_joueur -lt $nbJoueurs ]
            do
                kill -s USR2 `awk -v var=$nb_joueur '(NR==var+1){print $2}' inscrit.noms`
                ((nb_joueur=nb_joueur+1))
            done
        En_JEU=false
        Etablir_Classement
    fi

}
Etablir_Classement()
{
    RatioPartie=`echo "scale=2;$((nbRound-1))*$nbJoueurs" | bc`
    ligne=2
    while [ $ligne -le `awk 'END{print NR}' classement.joueurs` ]
    do
        Text[$((ligne-2))]=`awk -v var=$ligne '(NR==var){for (i=2; i<NF; i++) printf $i " "; print $NF}' classement.joueurs`
        Ratio[$((ligne-2))]=`awk -v var=$ligne '(NR==var){print $15}' classement.joueurs`
        ((ligne=ligne+1))
    done
    printf "\t\tTOP10 Joueurs/rounds:\n" > classement.joueurs
    Ratio[${#Ratio[@]}]=$RatioPartie
    i=0
    RatioTries=($(for l in ${Ratio[@]}; do echo $l; done | sort -r -n));unset Ratio

    while [ $i -lt ${#RatioTries[@]} ] && [ $i -lt 10 ]
    do
    pos=0
    while [ $pos -lt ${#Text[@]} ] && \
    [ "${RatioTries[$i]}" != "$(echo ${Text[$pos]} | awk '{print $14}')" ]
    do
    ((pos=pos+1))
    done 
    if [ $pos == ${#Text[@]} ]
    then  
    echo "$((i+1))- Nombre Joueurs : $nbJoueurs // Rounds cons??cutifs r??ussies : $((nbRound-1)) // Ratio : $RatioPartie // Date : $(date "+%d-%m-%Y %H:%M:%S")" >> classement.joueurs
    else
    echo "$((i+1))- ${Text[$pos]}" >> classement.joueurs
    Text[$pos]="termin??"
    fi
    ((i=i+1))
    done
    unset Text
    unset RatioTries
    
    
}
main()
{
    En_JEU=true
    Init_Jeu #Initialiser le jeu
    Random_Melange #Melanger les cartes
    Distribuer_Cartes #Destribuer les cartes
    while [ $En_JEU = true ]
    do
    trap 'Carte_Posee' USR2
    done
    nb_joueur=0
    awk '{print}' classement.joueurs
    #Fin du jeu on termine tous les processus joueurs           
    while [ $nb_joueur -lt $nbJoueurs ]
        do
            kill -s TERM `awk -v var=$nb_joueur '(NR==var+1){print $2}' inscrit.noms`
            ((nb_joueur=nb_joueur+1))
        done


}

main
