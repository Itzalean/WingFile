     š*   Affiche la description de fichiers.
     š*      Sert de "frontend" au rabais pour DSPFD et DSPFFD
     š*
     š*   Version 1.0
     š*      Utilise les fichiers gänäräs par les commandes DSPFD et DSPFFD
     š*      Ces fichiers sont placäs dans QTEMP et sont gänäräs dans le CL WINGFILEC1
     š*
     š*   License GPL V3.0
     š*      Lien : https://www.gnu.org/licenses/gpl-3.0-standalone.html
     š*
     š*
     š*
     H DftActGrp(*No)
     š*
     š*   Liste des fichiers utilisäs
     š*
     FWingFileD1CF   E             WorkStn IndDs(DspfDs) SFile(WINGSFL:SFLRCD)
     FWingFileP1O    E             Printer UsrOpn OflInd(wOverflow)
     š*   Fichiers de travail
     FWDSPFD    IF   E             DISK
     FWDSPFFD   IF   E             DISK
     š*
     š*   Däfinition des variables / DS / Paramütres / Etc
     š*
     D DspfDs          DS
     D  SflFold               11     11N
     D  SflPos                20     20N
     D  SflDspCtl             30     30N
     D  SflDsp                31     31N
     š*
     D CenterString    PR            50    Varying
     D  pText                        50    Value
     D  pLength                       2P 0 Value
     š*
     D CurFormat       S                   Like(WFNAME)
     D wFldi           S             10    Varying
     D wOverflow       S              1N   Inz(*Off)
     D wPos            S                   Like(SflRcd)
     š*
     š*   Le Programme
     š*
      /Free

    š  //   Boucle de traitement
       Dow Not *INLR;

          SflFold = WFMODE;
          Exfmt WINGCTL;
          Select;
    š        //   F3 = Quitter ou F12=Annuler
             When *INKC Or *INKL;
                *INLR = *On;
    š        //   F21 = Imprimer
             When *INKV;
                Exsr PrintSR;
    š        //   Positionnement dans le sous-fichier en fonction de la zone de recherche
             When WFPosition <> *Blank;
                Exsr SearchSR;
          EndSl;
       EndDo;

    š  //   Bye bye
       *INLR = *On;
       Return;
    š  //*************************************************************çç
    š  //   Initialisation du programme                               çç
    š  //*************************************************************çç
       BegSR *InzSR;

    š     //   Initialisation de l'äcran
          Read WDSPFD;
          If Not %Eof;
    š        //   Entête
             WfFILE = CenterString(%Trimr(ATLIB) + '/' + %Trim(ATFILE) +
                ' - Type : ' + ATFILA:40);
             WFTXT = CenterString(ATTXT:50);
          Else;
             Dsply 'Däsolä. Il y a eu un problüme  :(';
          EndIF;

          Exsr LoadSflSR;

       EndSR;
    š  //*************************************************************çç
    š  //   Initialisation de l'affichager                            çç
    š  //      Format de contrôle                                     çç
    š  //      Bas de l'äcran (touches de fonction)                   çç
    š  //*************************************************************çç
       BegSR InitSflSR;

          SFLRCD = *Zero;
          SflDspCtl = *off;
          SflDsp = *off;
          Write WINGCTL;
          SflDspCtl = *On;
          WFMODE = *On;

          Write WINGFOOT;

       EndSR;
    š  //*************************************************************çç
    š  //   Chargement du sous-fichier                                çç
    š  //   Boucle de lecture sur DSPFFD                              çç
    š  //*************************************************************çç
       BegSR LoadSflSR;

          ExSr InitSflSR;

          Read WDSPFFD;
          Dow Not %Eof;

             SFLRCD += 1;
             WFFLDI = WHFLDI;
             WFFLDT = WHFLDT;
    š        //   Diffärence d'affichage des däcimales selon que la zone est numärique ou pas
             If WFFLDT <> 'A';
                WFFLDB = WHFLDD;
                evalr WFFLDP = %Char(WHFLDP);
             Else;
                WFFLDB = WHFLDB;
                WFFLDP = *Blank;
             EndIf;
             WFFOBO = WHFOBO;
             WFPOSF = WHFOBO + WHFLDB - 1;
    š        //   Le nom du format n'est affichä qu'une fois
             If CurFormat <> WHNAME;
                WFNAME = CenterString(WHNAME:10);
                CurFormat = WHNAME;
             Else;
                WFNAME = CenterString('""':10);
             EndIf;
             WFFTXT = WHFTXT;

    š        //   Les entêtes de colonnes (COLHDG), affichäs sur la deuxiüme ligne
             WFCHD1 = WHCHD1;
             WFCHD2 = WHCHD2;
             WFCHD3 = WHCHD3;

             Write WINGSFL;

             Read WDSPFFD;
          EndDo;

          WFRRN = 1;
          If SFLRCD > 1;
             SflDsp = *on;
          EndIf;

       EndSR;
    š  //*************************************************************çç
    š  //   Impression de la description du fichier                   çç
    š  //*************************************************************çç
       BegSR PrintSR;

          Open WingFileP1;

    š     //   Le nom du fichier et sa description ne sont pas cadräs de
    š     //    la même faÖon que dans l'äcran d'oö des noms diffärents ^^
          WEFILE = %Trim(WFFILE);
          WETXT = %Trim(WFTXT);

          Write WFEntete;
          Write Separateur;

          Wpos = 1;
          Chain wPos WingSfl;

    š     //   Lecture du sous-fichier pour remplir l'ätat
          Dow %Found;

             Write Detail;

    š        //   Saut de page
             If wOverflow;
                Write Separateur;
                Write WFEntete;
                Write Separateur;
                wOverflow = *Off;
             EndIf;

             wPos += 1;
             Chain wPos WingSfl;
          EndDo;

          Write Separateur;
          Close WingFileP1;

       EndSR;
    š  //*************************************************************çç
    š  //   Recherche sur le nom de la zone                           çç
    š  //*************************************************************çç
       BegSR SearchSR;

          wFldi = %Trim(WFPosition);
          WFPosition = *Blank;
          wPos = 1;

    š     //   Recherche de la premiüre occurence
    š     //    Trop fänäant pour chercher les suivantes
          Chain wPos WingSfl;
          Dow %Found;
             If %Scan(wFldi:WFFLDI) <> *Zero;
                SflPos = *On;
                wfrrn = wPos;
                SflRcd = wPos;
                Update WingSfl;
                Leave;
             EndIf;
             SflPos = *Off;
             Update WingSfl;
             wPos += 1;
             Chain wPos WingSfl;
          EndDo;

       EndSR;

      /End-Free
     š***************************************************************
     š*   Sous-procädure de centrage de chaînes de caractüres       *
     š***************************************************************
     PCenterString     B
     š*
     D CenterString    PI            50    Varying
     D  pText                        50    Value
     D  pLength                       2P 0 Value
     š*
     D  wMess          S             50    Varying
     D  wLength        S                   Like(pLength)
     D  wStart         S                   Like(pLength)
     š*
      /Free

         %Len(wMess) = pLength;
         wLength = %Len(%Trim(pText));
         wStart = (pLength - wLength) / 2 + 1;
         %Subst(wMess:wStart:wLength) = %Trim(pText);
         Return wMess;

      /End-free

     PCenterString     E
