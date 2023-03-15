select object_name 
from objet 
where id_object in (
select id_object 
from quotation 
where id_object in (
select objet.id_object 
from liste_objet 
left join objet 
on liste_objet.id_object = objet.id_object 
where id_list in (
select id_list 
from liste 
where list_name not like '%wish%')      
group by objet.id_object,objet.object_name 
having count(liste_objet.id_object) >= 20) 
group by id_object 
having avg(object_score) > 14);