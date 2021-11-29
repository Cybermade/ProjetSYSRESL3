#!/bin/bash
Init_Joueur()
{

echo "Veuillez entrer votre nom s'il vous plait"
read NomJoueur
echo "$NomJoueur $$">>inscrit.noms
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
    clear;
    echo "Veuillez choisir une carte entre ${MesCartes[*]}" 
    read choixCarte
    #Verifier qu'il veut jouer une carte qu'il posséde
    while [[ ! " ${MesCartes[*]} " =~ " ${choixCarte} " ]]
    do
    clear;
    echo "Vous ne possédez pas cette carte veuillez rechoisir entre ${MesCartes[*]}"
    read choixCarte
    done
    ((carteJouees=carteJouees+1))
    echo "$choixCarte" >> round.en.cours
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
    trap 'printf "Cartes Jouées round :";awk '"'"'{printf "%s"" ",$0}END{printf "\n"}'"'"' round.en.cours' USR2
    Init_Joueur
    trap 'Recuperation_Carte' USR1
    while true; do
    :
    done
}

main