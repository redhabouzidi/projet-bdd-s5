select object_name 
from objet
where id_object in (
SELECT id_object 
FROM quotation
where comment_date >= sysdate - 7
GROUP BY id_object 
HAVING COUNT (id_object)=( 
SELECT MAX(compteur) 
FROM ( 
SELECT id_object, COUNT(id_object) compteur
FROM quotation
GROUP BY id_object)));