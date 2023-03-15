set serveroutput on

DROP TABLE AR_LISTE_OBJET;
DROP TABLE ARCHIVE;
DROP TABLE LISTE_OBJET;
DROP TABLE LISTE;
DROP TABLE QUOTATION;
DROP TABLE NOUVEAUTE_OBJET;
DROP TABLE OBJET;
DROP TABLE UTILISATEUR;
DROP TABLE NOUVEAUTE;

DROP SEQUENCE seq_user;
DROP SEQUENCE seq_objet;
DROP SEQUENCE seq_quote;
DROP SEQUENCE seq_liste;
DROP SEQUENCE seq_archive;
DROP SEQUENCE seq_nouveaute;


CREATE TABLE UTILISATEUR(
        id_user           Int NOT NULL,
        name              Varchar (50) NOT NULL,
        firstname         Varchar (50) NOT NULL,
        address           Varchar (100) NOT NULL,
        birthday          Date NOT NULL,
        registration_date Date NOT NULL,
        login             Varchar(10) NOT NULL UNIQUE,
        password          Varchar (20) NOT NULL,
	    CONSTRAINT UTILISATEUR_PK PRIMARY KEY (id_user),
        CONSTRAINT CHK_PASSWORD CHECK(REGEXP_LIKE (password, '^[a-zA-Z0-9_]*$' )), 
        constraint CHK_LOGIN check(substr(LOWER(firstname),0,1)=substr(login,0,1) AND substr(LOWER(name),0,7)=substr(login,2,length(login)-3) AND REGEXP_LIKE(substr(login,length(login)-1,2),'^[0-9]{2}$')),
        CONSTRAINT CHK_birthday_registration check(registration_date > birthday)
);

CREATE TABLE NOUVEAUTE(
    id_list INTEGER NOT NULL,
    area DATE,
    CONSTRAINT NEW_LIST_PK PRIMARY KEY (id_list)
);

CREATE TABLE OBJET(
        id_object    Int NOT NULL,
        object_name  Varchar (50) NOT NULL UNIQUE,
        object_type  Varchar (50) NOT NULL,
        object_theme Varchar (50) NOT NULL,
	CONSTRAINT OBJET_PK PRIMARY KEY (id_object)
);
CREATE TABLE NOUVEAUTE_OBJET(
        id_object int NOT NULL,
        id_list int NOT NULL,
        CONSTRAINT NOUVEAUTE_OBJET_FK FOREIGN KEY (id_object) REFERENCES OBJET(id_object),
        CONSTRAINT NOUVEAUTE_OBJET_FK1 FOREIGN KEY (id_list) REFERENCES NOUVEAUTE(id_list)
);

CREATE TABLE QUOTATION(
        id_quotation   Int NOT NULL,
        object_score   Int,
        note_date      date,
        object_comment Varchar (50),
        comment_date   date,
        id_object      Int NOT NULL,
        id_user        Int NOT NULL,
	    CONSTRAINT QUOTATION_PK PRIMARY KEY (id_quotation),
	    CONSTRAINT QUOTATION_OBJET_FK FOREIGN KEY (id_object) REFERENCES OBJET(id_object),
	    CONSTRAINT QUOTATION_UTILISATEUR0_FK FOREIGN KEY (id_user) REFERENCES UTILISATEUR(id_user),
	CONSTRAINT CHK_SCORE CHECK (object_score <= 20 and object_score >= 0)
);

CREATE TABLE LISTE(
        id_list      Int NOT NULL,
        list_name    Varchar (50) NOT NULL,
        list_type    Varchar (50) NOT NULL,
        list_comment Varchar (50),
        id_user      Int NOT NULL,
	    CONSTRAINT LISTE_PK PRIMARY KEY (id_list),
	    CONSTRAINT LISTE_UTILISATEUR_FK FOREIGN KEY (id_user) REFERENCES UTILISATEUR(id_user)
);

CREATE TABLE LISTE_OBJET(
        id_list   Int NOT NULL,
        id_object Int NOT NULL,
	    CONSTRAINT LISTE_OBJET_PK PRIMARY KEY (id_list,id_object),
	    CONSTRAINT LISTE_OBJET_LISTE_FK FOREIGN KEY (id_list) REFERENCES LISTE(id_list),
        CONSTRAINT LISTE_OBJET_OBJET0_FK FOREIGN KEY (id_object) REFERENCES OBJET(id_object)
);

CREATE TABLE ARCHIVE(
        id_user         INT NOT NULL,
        id_list         INT NOT NULL,
        ar_list_name VARCHAR(50) NOT NULL,
	CONSTRAINT ARCHIVE_UTILISATEUR_FK FOREIGN KEY (id_user) REFERENCES UTILISATEUR(id_user),
        CONSTRAINT ARCHIVE_LISTE_FK PRIMARY KEY (id_list)
);

CREATE TABLE AR_LISTE_OBJET(
        id_list INT NOT NULL,
        id_object Int NOT NULL,
        CONSTRAINT AR_LISTE_OBJET_PK PRIMARY KEY (id_list,id_object),
	CONSTRAINT AR_LISTE_OBJET_LISTE_FK FOREIGN KEY (id_list) REFERENCES LISTE(id_list),
        CONSTRAINT AR_LISTE_OBJET_OBJET0_FK FOREIGN KEY (id_object) REFERENCES OBJET(id_object)
);


CREATE SEQUENCE seq_user START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_objet START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_quote START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_liste START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_archive START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_nouveaute START WITH 1 INCREMENT BY 1;

CREATE INDEX idx_quotation_user_objet ON quotation (id_user,id_object);
CREATE INDEX idx_liste_objet on liste_objet (id_object,id_list);
CREATE INDEX idx_liste_user ON liste (id_list,id_user);



CREATE OR REPLACE TRIGGER arch
AFTER DELETE ON LISTE
FOR EACH ROW
BEGIN
    insert into ARCHIVE values (:old.id_user,:old.id_list,:old.list_name);
END;
/

CREATE OR REPLACE TRIGGER arch_obj
AFTER DELETE ON LISTE_OBJET
FOR EACH ROW
DECLARE
idl ARCHIVE.id_list%type;
s LISTE%ROWTYPE;
BEGIN 
    select id_list into idl from ARCHIVE where id_list = :old.id_list;
    insert into AR_LISTE_OBJET values (:old.id_list,:old.id_object);
    EXCEPTION 
        when NO_DATA_FOUND then
            select * into s from LISTE where id_list = :old.id_list; 
            insert into ARCHIVE values (s.id_user,s.id_list,s.list_name);
            insert into AR_LISTE_OBJET values (:old.id_list,:old.id_object);

END;
/

CREATE OR REPLACE TRIGGER objects_tr
AFTER INSERT ON OBJET
FOR EACH ROW
DECLARE
    t DATE;
    d INTEGER;
    idl nouveaute.id_list%type;
BEGIN

        t := to_date(extract(year from sysdate())||'/'||extract(month from sysdate()),'YYYY/MM');
        select id_list into idl from NOUVEAUTE where area = t ;
        insert into nouveaute_objet values(:new.id_object,idl);
        EXCEPTION 
        WHEN NO_DATA_FOUND then
                d:=seq_nouveaute.nextval;
                insert into nouveaute values (d,t);
                insert into nouveaute_objet values(:new.id_object,d);
END;
/


CREATE OR REPLACE TRIGGER registration_check
        BEFORE INSERT OR UPDATE ON UTILISATEUR
        FOR EACH ROW
BEGIN
        IF(:new.registration_date > SYSDATE )
        THEN
                RAISE_APPLICATION_ERROR( -20001, 'Date inscription doit etre inferieur a la date actuel');
        END IF;
END;
/

CREATE OR REPLACE TRIGGER note_date_check
        BEFORE INSERT OR UPDATE ON QUOTATION
        FOR EACH ROW
BEGIN
        IF(:new.note_date > SYSDATE )
        THEN
                RAISE_APPLICATION_ERROR( -20002, 'Date de la note doit etre inférieur à la date actuel');
        END IF;
END;
/

CREATE OR REPLACE TRIGGER comment_date_check
        BEFORE INSERT OR UPDATE ON QUOTATION
        FOR EACH ROW
BEGIN
        IF(:new.comment_date > sysdate)
        THEN
                RAISE_APPLICATION_ERROR( -20003, 'Date du commentaire doit etre inférieur à la date actuel');
        END IF;
END;
/



insert into UTILISATEUR values (seq_user.nextval,'ELBOUHI','Houssam','14 route de la wantzenau','23-05-2001','01-11-2018','helbouhi22','elbouhi123');
insert into UTILISATEUR values (seq_user.nextval,'LEWANDOWSKI','Robert','15 rue du paradis','21-08-1988','05-02-2018','rlewando19','robert_123');
insert into UTILISATEUR values (seq_user.nextval,'PREUDHOMME','Anass','558 avenue de la richesse','20-01-2006','19-04-2015','apreudho88','Anass123456');
insert into UTILISATEUR values (seq_user.nextval,'ELBOUHI','Hamid','74 route de la compagne','01-01-2000','22-02-2018','helbouhi99','_hamid123');
insert into UTILISATEUR values (seq_user.nextval,'DARMIAN','Joel','12 rue de la fontaine','01-08-2000','20-10-2018','jdarmian55','Joeldarmian12');
insert into UTILISATEUR values (seq_user.nextval,'CHEMAKH','Marouane','5 route de Metz','02-02-2002','06-09-2018','mchemakh36','marouane123');
insert into UTILISATEUR values (seq_user.nextval,'HEIMERDINGER','Laurent','5 route de Marseille','02-02-1999','06-09-2018','lheimerd11','heimer123');
insert into UTILISATEUR values (seq_user.nextval,'FORTUNE','Marine','5 route de Nancy','24-05-2001','06-09-2018','mfortune11','fortune123');
insert into UTILISATEUR values (seq_user.nextval,'CARPENTIER','Carla','5 route de Sint','01-04-2001','06-09-2018','ccarpent99','carla_147');
insert into UTILISATEUR values (seq_user.nextval,'Fournier','Sybile','465 avenue de bourgeois','13-11-2002','06-10-2019','sfournie41','fourn1');
insert into UTILISATEUR values (seq_user.nextval,'BERTRAND','Jamila','5 route de Niort','19-12-2001','11-09-2018','jbertran11','jamila_123');
insert into UTILISATEUR values (seq_user.nextval,'ROUSSEAU','Sarah','52 route de Perpignan','11-03-2001','06-09-2018','sroussea52','sarahmer1_2');
insert into UTILISATEUR values (seq_user.nextval,'MERCIER','Lea','69 route de Grenoble','14-07-2001','06-09-2018','lmercier10','lea1mercier');
insert into UTILISATEUR values (seq_user.nextval,'GAUTHIER','Robin','47 route de Calais','31-07-2001','06-09-2018','rgauthie44','gauthier11');
insert into UTILISATEUR values (seq_user.nextval,'LEFEVRE','Paul','112 route de Lille','30-06-2001','06-09-2018','plefevre99','le_fevre');
insert into UTILISATEUR values (seq_user.nextval,'PERRIN','Blaise','1245 route de Toulouse','03-04-2001','06-09-2018','bperrin08','per8rin');
insert into UTILISATEUR values (seq_user.nextval,'FERNANDEZ','Kylian','745 route de Bordeaux','20-11-2001','06-09-2018','kfernand50','fernandez123');
insert into UTILISATEUR values (seq_user.nextval,'JACQUET','Rami','2 route de Ushuaia','21-02-2001','06-09-2018','rjacquet36','rami1456');
insert into UTILISATEUR values (seq_user.nextval,'BOULANGER','Charles','14 route de Rome','11-09-2001','06-09-2018','cboulang78','_charles');
insert into UTILISATEUR values (seq_user.nextval,'MARTINEZ','Lamia','72 route de Paris','22-05-2001','06-09-2018','lmartine01','martinez_');
insert into UTILISATEUR values (seq_user.nextval,'ELHAMDAOUI','Lionel','13 place edison','13-02-2001','12-03-2018','lelhamda55','hamdaouirajawi');
insert into UTILISATEUR values (seq_user.nextval,'ZIYECH','Hakim','14 place samur','29-05-1990','12-04-2017','hziyech12','ziyech_hakim');
insert into UTILISATEUR values (seq_user.nextval,'ELBAKIKI','Mohcine','1 rue le four','30-06-1992','22-11-2016','melbakik88','mohcinemitouali');



insert into OBJET values (seq_objet.nextval,'John Wick','film','action');
insert into OBJET values (seq_objet.nextval,'Titanic','film','romance');
insert into OBJET values (seq_objet.nextval,'Star wars','film','science fiction');
insert into OBJET values (seq_objet.nextval,'Uncharted','film','aventure');
insert into OBJET values (seq_objet.nextval,'Skyfall','film','action');
insert into OBJET values (seq_objet.nextval,'Dark','serie','science fiction');
insert into OBJET values (seq_objet.nextval,'Simpson','serie','comedie');
insert into OBJET values (seq_objet.nextval,'Family guy','serie','comedie');
insert into OBJET values (seq_objet.nextval,'Blacklist','serie','action');
insert into OBJET values (seq_objet.nextval,'The good doctor','serie','drame');
insert into OBJET values (seq_objet.nextval,'Fifa 23','jeu video','sport');
insert into OBJET values (seq_objet.nextval,'GTA5','jeu video','action');
insert into OBJET values (seq_objet.nextval,'Forza','jeu video','sport');
insert into OBJET values (seq_objet.nextval,'Dark souls','jeu video','aventure');
insert into OBJET values (seq_objet.nextval,'Among us','jeu video','enigme');
insert into OBJET values (seq_objet.nextval,'Germinal','Livre','drame');
insert into OBJET values (seq_objet.nextval,'Sherlock Holmes','Livre','policier');
insert into OBJET values (seq_objet.nextval,'Cendrillon','Livre','romance');
insert into OBJET values (seq_objet.nextval,'Tintin','Livre','action');
insert into OBJET values (seq_objet.nextval,'Batman','Livre','action');
insert into OBJET values (seq_objet.nextval,'Fast and furious','film','action');
insert into OBJET values (seq_objet.nextval,'Trackers','film','action');
insert into OBJET values (seq_objet.nextval,'The Purge','film','Horreur');
insert into OBJET values (seq_objet.nextval,'Interstellar','film','science fiction');
insert into OBJET values (seq_objet.nextval,'Rocky','film','sport');
insert into OBJET values (seq_objet.nextval,'Ali','film','sport');
insert into OBJET values (seq_objet.nextval,'Wanted','film','action');
insert into OBJET values (seq_objet.nextval,'Her','film','romance');
insert into OBJET values (seq_objet.nextval,'League of legends','jeu video','Moba');
insert into OBJET values (seq_objet.nextval,'Valorant','jeu video','tir');
insert into OBJET values (seq_objet.nextval,'chess online','jeu video','stratégie');
insert into OBJET values (seq_objet.nextval,'Just cause 4','jeu video','aventure');
insert into OBJET values (seq_objet.nextval,'Need for speed','jeu video','sport');
insert into OBJET values (seq_objet.nextval,'CS GO','jeu video','tir');
insert into OBJET values (seq_objet.nextval,'Paladins','jeu video','Moba');
insert into OBJET values (seq_objet.nextval,'Super mario','jeu video','aventure');
insert into OBJET values (seq_objet.nextval,'Battlefield V','jeu video','tir');
insert into OBJET values (seq_objet.nextval,'call of duty modern warfare','jeu video','tir');
insert into OBJET values (seq_objet.nextval,'PUBG','jeu video','tir');



insert into QUOTATION values (seq_quote.nextval,18,'22-08-2019','la legende','20-11-2022',16,1);
insert into QUOTATION values (seq_quote.nextval,7,'03-09-2019','ca va','21-11-2022',18,1);
insert into QUOTATION values (seq_quote.nextval,15,'11-10-2019','nostalgie','23-11-2022',19,1);
insert into QUOTATION values (seq_quote.nextval,20,'01-01-2020','meilleur film pour toujours','24-11-2022',1,1);
insert into QUOTATION values (seq_quote.nextval,14,'06-06-2020','viens de sortir','11-11-2022',4,1);
insert into QUOTATION values (seq_quote.nextval,13,'01-01-2021','NUL','01-11-2022',7,1);
insert into QUOTATION values (seq_quote.nextval,14,'10-07-2021','fun','20-11-2022',8,1);
insert into QUOTATION values (seq_quote.nextval,15,'12-09-2021','typical american series','02-11-2022',9,1);
insert into QUOTATION values (seq_quote.nextval,12,'13-09-2021','si passionne par la medecine','10-11-2022',10,1);
insert into QUOTATION values (seq_quote.nextval,20,'10-10-2021','meilleur jeu du monde','22-11-2022',11,1);
insert into QUOTATION values (seq_quote.nextval,14,'11-11-2021','NULL','17-11-2022',13,1);
insert into QUOTATION values (seq_quote.nextval,17,'02-09-2022','difficile','18-11-2022',14,1);
insert into QUOTATION values (seq_quote.nextval,20,'01-04-2021','rien a dire','22-11-2022',16,2);
insert into QUOTATION values (seq_quote.nextval,18,'17-05-2021','Suspense','10-11-2022',17,2);
insert into QUOTATION values (seq_quote.nextval,2,'23-06-2021',NULL,NULL,6,2);
insert into QUOTATION values (seq_quote.nextval,0,'03-11-2020','pas mon style','22-11-2022',10,2);
insert into QUOTATION values (seq_quote.nextval,10,'11-11-2020','Pas mal comme jeu multijoueur','09-11-2022',15,2);
insert into QUOTATION values (seq_quote.nextval,2,'14-08-2021','Dicaprio meeh :(','23-11-2022',2,3);
insert into QUOTATION values (seq_quote.nextval,2,'13-03-2021','Pas fun de la science fiction','02-11-2022',3,3);
insert into QUOTATION values (seq_quote.nextval,18,'11-12-2021','Fantastique','22-11-2022',4,3);
insert into QUOTATION values (seq_quote.nextval,18,'04-04-2020','Meilleur jeu de sport','23-11-2022',11,3);
insert into QUOTATION values (seq_quote.nextval,0,'30-09-2022','Degeulace','10-11-2022',20,4);
insert into QUOTATION values (seq_quote.nextval,20,'06-10-2022','Parfait','25-11-2022',1,4);
insert into QUOTATION values (seq_quote.nextval,11,'01-11-2022','Passable','22-11-2022',5,4);
insert into QUOTATION values (seq_quote.nextval,13,'22-03-2022',NULL,NULL,7,4);
insert into QUOTATION values (seq_quote.nextval,4,'09-02-2022',NULL,NULL,8,4);
insert into QUOTATION values (seq_quote.nextval,10,'07-11-2021',NULL,NULL,17,5);
insert into QUOTATION values (seq_quote.nextval,10,'01-02-2019',NULL,NULL,20,5);
insert into QUOTATION values (seq_quote.nextval,10,'18-05-2022','Keanu REEVES <3','26-11-2022',1,5);
insert into QUOTATION values (seq_quote.nextval,10,'19-11-2021',NULL,NULL,6,5);
insert into QUOTATION values (seq_quote.nextval,10,'26-10-2022',NULL,NULL,7,5);
insert into QUOTATION values (seq_quote.nextval,10,'01-01-2022',NULL,NULL,11,5);
insert into QUOTATION values (seq_quote.nextval,9,'05-11-2022',NULL,NULL,18,6);
insert into QUOTATION values (seq_quote.nextval,12,'05-11-2022','Action au top','24-11-2022',1,6);
insert into QUOTATION values (seq_quote.nextval,10,'05-11-2022',NULL,NULL,2,6);
insert into QUOTATION values (seq_quote.nextval,9,'05-11-2022',NULL,NULL,7,6);
insert into QUOTATION values (seq_quote.nextval,13,'05-11-2022',NULL,NULL,8,6);
insert into QUOTATION values (seq_quote.nextval,19,'05-11-2022',NULL,NULL,9,6);
insert into QUOTATION values (seq_quote.nextval,14,'05-11-2022',NULL,NULL,1,7);
insert into QUOTATION values (seq_quote.nextval,10,'05-11-2022',NULL,NULL,1,8);
insert into QUOTATION values (seq_quote.nextval,17,'05-11-2022',NULL,NULL,1,9);
insert into QUOTATION values (seq_quote.nextval,18,'05-11-2022',NULL,NULL,1,10);
insert into QUOTATION values (seq_quote.nextval,16,'05-11-2022',NULL,NULL,1,11);
insert into QUOTATION values (seq_quote.nextval,15,'05-11-2022',NULL,NULL,1,12);
insert into QUOTATION values (seq_quote.nextval,15,'05-11-2022',NULL,NULL,1,13);
insert into QUOTATION values (seq_quote.nextval,14,'05-11-2022',NULL,NULL,1,14);
insert into QUOTATION values (seq_quote.nextval,16,'05-11-2022',NULL,NULL,1,15);
insert into QUOTATION values (seq_quote.nextval,12,'05-11-2022',NULL,NULL,1,16);
insert into QUOTATION values (seq_quote.nextval,16,'05-11-2022',NULL,NULL,1,17);
insert into QUOTATION values (seq_quote.nextval,15,'05-11-2022',NULL,NULL,1,18);
insert into QUOTATION values (seq_quote.nextval,19,'05-11-2022',NULL,NULL,1,19);
insert into QUOTATION values (seq_quote.nextval,20,'05-11-2022',NULL,NULL,1,20);
insert into QUOTATION values (seq_quote.nextval,11,'05-11-2022',NULL,NULL,1,21);
insert into QUOTATION values (seq_quote.nextval,13,'05-11-2022',NULL,NULL,1,22);
insert into QUOTATION values (seq_quote.nextval,13,'05-11-2022',NULL,NULL,1,23);
insert into QUOTATION values (seq_quote.nextval,10,'11-12-2022',NULL,NULL,21,1);
insert into QUOTATION values (seq_quote.nextval,12,'11-12-2022',NULL,NULL,22,1);
insert into QUOTATION values (seq_quote.nextval,14,'11-12-2022',NULL,NULL,23,1);
insert into QUOTATION values (seq_quote.nextval,8,'11-12-2022',NULL,NULL,24,1);
insert into QUOTATION values (seq_quote.nextval,7,'11-12-2022',NULL,NULL,25,1);
insert into QUOTATION values (seq_quote.nextval,6,'11-12-2022',NULL,NULL,26,1);
insert into QUOTATION values (seq_quote.nextval,17,'11-12-2022',NULL,NULL,27,1);
insert into QUOTATION values (seq_quote.nextval,14,'11-12-2022',NULL,NULL,2,1);
insert into QUOTATION values (seq_quote.nextval,15,'11-12-2022',NULL,NULL,3,1);
insert into QUOTATION values (seq_quote.nextval,20,'11-12-2022',NULL,NULL,29,1);
insert into QUOTATION values (seq_quote.nextval,17,'11-12-2022',NULL,NULL,30,1);
insert into QUOTATION values (seq_quote.nextval,12,'11-12-2022',NULL,NULL,31,1);
insert into QUOTATION values (seq_quote.nextval,13,'11-12-2022',NULL,NULL,32,1);
insert into QUOTATION values (seq_quote.nextval,4,'11-12-2022',NULL,NULL,33,1);
insert into QUOTATION values (seq_quote.nextval,5,'11-12-2022',NULL,NULL,34,1);
insert into QUOTATION values (seq_quote.nextval,11,'11-12-2022',NULL,NULL,35,1);
insert into QUOTATION values (seq_quote.nextval,12,'11-12-2022',NULL,NULL,36,1);
insert into QUOTATION values (seq_quote.nextval,10,'11-12-2022',NULL,NULL,37,1);
insert into QUOTATION values (seq_quote.nextval,10,'11-12-2022',NULL,NULL,38,1);
insert into QUOTATION values (seq_quote.nextval,9,'11-12-2022',NULL,NULL,12,2);
insert into QUOTATION values (seq_quote.nextval,19,'11-12-2022',NULL,NULL,14,2);
insert into QUOTATION values (seq_quote.nextval,17,'11-12-2022',NULL,NULL,32,2);
insert into QUOTATION values (seq_quote.nextval,11,'11-12-2022',NULL,NULL,33,2);
insert into QUOTATION values (seq_quote.nextval,12,'11-12-2022',NULL,NULL,34,2);
insert into QUOTATION values (seq_quote.nextval,14,'11-12-2022',NULL,NULL,35,2);
insert into QUOTATION values (seq_quote.nextval,14,'11-12-2022',NULL,NULL,36,2);
insert into QUOTATION values (seq_quote.nextval,14,'11-12-2022',NULL,NULL,37,2);
insert into QUOTATION values (seq_quote.nextval,16,'11-12-2022',NULL,NULL,38,2);
insert into QUOTATION values (seq_quote.nextval,7,'11-12-2022',NULL,NULL,39,2);



insert into LISTE values (seq_liste.nextval,'liste livre','livre','my list of books',1);
insert into LISTE values (seq_liste.nextval,'liste film','film','my list of movies',1);
insert into LISTE values (seq_liste.nextval,'liste serie','serie','my list of series',1);
insert into LISTE values (seq_liste.nextval,'liste jeu video','jeu video','my list of video games',1);
insert into LISTE values (seq_liste.nextval,'wish liste livre','livre','my wish list of books',1);
insert into LISTE values (seq_liste.nextval,'wish liste jeu video','jeu video','my wish list of video games',1);
insert into LISTE values (seq_liste.nextval,'liste livre','livre','ma liste des livres',2);
insert into LISTE values (seq_liste.nextval,'liste serie','serie','ma liste des series',2);
insert into LISTE values (seq_liste.nextval,'liste jeu video','jeu video','ma liste des jeux videos',2);
insert into LISTE values (seq_liste.nextval,'wish liste jeu video','jeu video','que jaime avoir comme jeux',2);
insert into LISTE values (seq_liste.nextval,'wish liste serie','serie','que jaime avoir comme series',2);
insert into LISTE values (seq_liste.nextval,'wish liste film','film','que jaime avoir comme films',2);
insert into LISTE values (seq_liste.nextval,'liste film','film','mes films',3);
insert into LISTE values (seq_liste.nextval,'liste jeu video','jeu video','mes jeux videos',3);
insert into LISTE values (seq_liste.nextval,'liste livre','livre','livres du rien du tout',4);
insert into LISTE values (seq_liste.nextval,'liste film','film',NULL,4);
insert into LISTE values (seq_liste.nextval,'liste serie','serie',NULL,4);
insert into LISTE values (seq_liste.nextval,'wish liste film','film','je souhiate avoir ces films',4);
insert into Liste values (seq_liste.nextval,'liste livre','livre',NULL,5);
insert into Liste values (seq_liste.nextval,'liste film','film',NULL,5);
insert into Liste values (seq_liste.nextval,'liste serie','serie',NULL,5);
insert into Liste values (seq_liste.nextval,'liste jeu video','jeu video',NULL,5);
insert into LISTE VALUES (seq_liste.nextval,'liste livre','livre',NULL,6);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,6);
insert into LISTE VALUES (seq_liste.nextval,'liste serie','serie',NULL,6);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,7);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,8);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,9);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,10);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,11);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,12);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,13);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,14);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,15);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,15);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,16);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,17);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,18);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,19);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,20);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,21);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,22);
insert into LISTE VALUES (seq_liste.nextval,'liste film','film',NULL,23);



insert into LISTE_OBJET values(1,16);
insert into LISTE_OBJET values(1,18);
insert into LISTE_OBJET values(1,19);
insert into LISTE_OBJET values(2,1);
insert into LISTE_OBJET values(2,4);
insert into LISTE_OBJET values(3,7);
insert into LISTE_OBJET values(3,8);
insert into LISTE_OBJET values(3,9);
insert into LISTE_OBJET values(3,10);
insert into LISTE_OBJET values(4,11);
insert into LISTE_OBJET values(4,13);
insert into LISTE_OBJET values(4,14);
insert into LISTE_OBJET values(5,17);
insert into LISTE_OBJET values(5,20);
insert into LISTE_OBJET values(6,12);
insert into LISTE_OBJET values(6,15);
insert into LISTE_OBJET values(7,16);
insert into LISTE_OBJET values(7,17);
insert into LISTE_OBJET values(8,6);
insert into LISTE_OBJET values(8,10);
insert into LISTE_OBJET values(9,15);
insert into LISTE_OBJET values(10,11);
insert into LISTE_OBJET values(10,13);
insert into LISTE_OBJET values(11,7);
insert into LISTE_OBJET values(11,8);
insert into LISTE_OBJET values(12,1);
insert into LISTE_OBJET values(12,2);
insert into LISTE_OBJET values(12,3);
insert into LISTE_OBJET values(13,2);
insert into LISTE_OBJET values(13,3);
insert into LISTE_OBJET values(13,4);
insert into LISTE_OBJET values(14,11);
insert into LISTE_OBJET values(15,20);
insert into LISTE_OBJET values(16,1);
insert into LISTE_OBJET values(16,5);
insert into LISTE_OBJET values(17,7);
insert into LISTE_OBJET values(17,8);
insert into LISTE_OBJET values(18,3);
insert into LISTE_OBJET values(19,17);
insert into LISTE_OBJET values(19,20);
insert into LISTE_OBJET values(20,1);
insert into LISTE_OBJET values(21,6);
insert into LISTE_OBJET values(21,7);
insert into LISTE_OBJET values(22,11);
insert into LISTE_OBJET values(23,18);
insert into LISTE_OBJET values(24,1);
insert into LISTE_OBJET values(24,2);
insert into LISTE_OBJET values(25,7);
insert into LISTE_OBJET values(25,8);
insert into LISTE_OBJET values(25,9);
insert into LISTE_OBJET values(26,1);
insert into LISTE_OBJET values(27,1);
insert into LISTE_OBJET values(28,1);
insert into LISTE_OBJET values(29,1);
insert into LISTE_OBJET values(30,1);
insert into LISTE_OBJET values(31,1);
insert into LISTE_OBJET values(32,1);
insert into LISTE_OBJET values(33,1);
insert into LISTE_OBJET values(34,1);
insert into LISTE_OBJET values(35,1);
insert into LISTE_OBJET values(36,1);
insert into LISTE_OBJET values(37,1);
insert into LISTE_OBJET values(38,1);
insert into LISTE_OBJET values(39,1);
insert into LISTE_OBJET values(40,1);
insert into LISTE_OBJET values(41,1);
insert into LISTE_OBJET values(2,2);
insert into LISTE_OBJET values(2,3);
insert into LISTE_OBJET values(2,21);
insert into LISTE_OBJET values(2,22);
insert into LISTE_OBJET values(2,23);
insert into LISTE_OBJET values(2,24);
insert into LISTE_OBJET values(2,25);
insert into LISTE_OBJET values(2,26);
insert into LISTE_OBJET values(2,27);
insert into LISTE_OBJET values(4,29);
insert into LISTE_OBJET values(4,30);
insert into LISTE_OBJET values(4,31);
insert into LISTE_OBJET values(4,32);
insert into LISTE_OBJET values(4,33);
insert into LISTE_OBJET values(4,34);
insert into LISTE_OBJET values(4,35);
insert into LISTE_OBJET values(4,36);
insert into LISTE_OBJET values(4,37);
insert into LISTE_OBJET values(4,38);
insert into LISTE_OBJET values(9,12);
insert into LISTE_OBJET values(9,14);
insert into LISTE_OBJET values(9,32);
insert into LISTE_OBJET values(9,33);
insert into LISTE_OBJET values(9,34);
insert into LISTE_OBJET values(9,35);
insert into LISTE_OBJET values(9,36);
insert into LISTE_OBJET values(9,37);
insert into LISTE_OBJET values(9,38);
insert into LISTE_OBJET values(9,39);



CREATE or REPLACE FUNCTION score_moyen(id Int)
RETURN float
IS
    count_result int := 0;
    score number(4,2);
    objet varchar(100);
BEGIN
    select count(object_score) into count_result from quotation where id_object = id;
    if count_result < 20 THEN RETURN 0;
    else
        select object_name into objet from objet where id_object = id;
        Select avg(object_score) into score from quotation where id_object = id;
        DBMS_OUTPUT.PUT_LINE('[ '||objet ||' ] a plus de 20 evaluations avec une moyenne de notation : ' || score); 
    end if;
    return score;
END;
/


create or replace procedure top_10 (id integer)
is
begin
        
        DBMS_OUTPUT.PUT_LINE('______________________');
        for  liste_ident in (
                select l.id_list
                from (select * from liste where (list_type='livre' or list_type='jeu video' or list_type='film') and list_name not like '%wish%' and id_user = id)l
                join (
                        select id_list,id_object
                        from LISTE_OBJET
                )lo on l.id_list=lo.id_list
                group by l.id_list,l.id_user
                having count(lo.id_object)>=10
        )   
        LOOP
                for objet in (
                        
                        select object_type,object_name,rownum from (
                                select distinct object_name,object_type,object_score,note_date
                                from (select * from liste_objet where id_list=liste_ident.id_list) lo 
                                join objet o 
                                on lo.id_object=o.id_object
                                left join (select * from quotation where id_user = id ) q
                                on lo.id_object=q.id_object
                                order by object_score desc,note_date)
                        where rownum <=10
                        
                )
                LOOP
                DBMS_OUTPUT.PUT_LINE(objet.object_type||' '||objet.object_name);
                end loop;
        DBMS_OUTPUT.PUT_LINE('______________________');
        end loop;
        
        
end;
/


create or replace procedure suggestion (id integer,x integer,y integer,z integer)
is

begin
for var in(
select distinct object_name,rownum from (
select distinct d1.id_object,d3.moyenne,o1.object_name
from quotation d1
join (
        select q3.id_object 
        from quotation q3 
        join (
                select distinct q1.id_user
                from quotation q1 
                join (
                        select * 
                        from quotation 
                        where id_user !=  id
                        )q2
                on q1.id_object = q2.id_object 
                and q1.object_score=q2.object_score 
                where q1.id_user = id
                group by q1.id_user ,q2.id_user
                having count(q2.id_object)>Z
        )q4
        on q3.id_user = q4.id_user
        join(
                select * 
                from quotation 
                where id_user != id
                )q4
        on q3.id_object = q4.id_object 
        where q3.id_user = id
        group by q3.id_object 
        having count(q4.id_user)>Y
        )d2
on d1.id_object=d2.id_object 
left join (
        select id_object , avg(object_score) moyenne 
        from quotation 
        group by id_object 
)d3
on d1.id_object = d3.id_object 
join objet o1 
on o1.id_object=d1.id_object
group by d1.id_object ,d3.moyenne,o1.object_name,rownum
order by d3.moyenne desc
)
where rownum <=X
)
loop
DBMS_OUTPUT.PUT_LINE(var.object_name);
end loop;


end;
/