#!/bin/bash
Init_Robot()
{


NameRobot=`awk 'BEGIN{count = 0} (/Robot/) {count++} END { print count }' inscrit.noms`
((NameRobot=NameRobot+1))
NameRobot="Robot"$NameRobot
echo "$NameRobot $$">>inscrit.noms
pidGestionJeu=`awk {print} gestion.jeu.pid`
kill -s USR1 $pidGestionJeu

}
Recuperation_Carte()
{   
    nbCartes=`awk '(NR==1) {print NF-2}' cartes.distruibuees.round`
    prendreCartes=0
    while [ $prendreCartes -lt $nbCartes ]
    do 
    MesCartes[$prendreCartes]=`awk -v var=$prendreCartes -v var2=$$ '($2==var2){print $(var+3)}' cartes.distruibuees.round`
    ((prendreCartes=prendreCartes+1))
    done
    Jouer      
}
Jouer()
{   
    carteJouees=0
    while [ $carteJouees -lt $nbCartes ]
    do
    echo "Veuillez choisir une carte entre ${MesCartes[*]}" 
    MesCartesTriees=($(for l in ${MesCartes[@]}; do echo $l; done | sort -n))
    choixCarte=${MesCartesTriees[0]}

    ((carteJouees=carteJouees+1))
    a=`echo "e($choixCarte/24)" | bc -l`
    sleep `echo "scale=5;$a/1.5" | bc`
    echo "$NameRobot $choixCarte" >> round.en.cours
    kill -s USR2 $pidGestionJeu
    pos=0
    
    if [ ${#MesCartes[@]} -ne 0 ]; then
        while [ "${MesCartes[$pos]}" != "$choixCarte" ]
        do
        ((pos=pos+1))
        done
        unset 'MesCartes[$pos]' #Enlever la carte jouée
    fi
    done
    echo "Vous avez joué toutes vos cartes, Veuillez attendre la fin du round"
    

}

main()
{
    trap 'echo "Cartes Jouées round :";awk '"'"'{print}'"'"' round.en.cours' USR2
    Init_Robot
    trap 'Recuperation_Carte' USR1
    while true; do
    :
    done
}

main