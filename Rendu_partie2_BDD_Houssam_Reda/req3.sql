select firstname , name , id_user 
from utilisateur 
where id_user in (
select distinct id_user 
from quotation 
group by id_user 
having min(object_score) > 8);