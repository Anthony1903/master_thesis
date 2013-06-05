# encoding: utf-8

require 'csv'

class CsvHasher

=begin

    files = description des fichiers à charger

    files est une liste de dictionnaire contenant chacun deux éléments
      => "path" : le chemin vers un fichier 
      => "name" : le nom du dictionnaire qui contiendra le contenu chargé depuis le chemin

=end
    def initialize(files = [])
        @files = files
    end

=begin

    Charge les fichiers un à un

    - Si le chargement s'est fait sans rencontrer d'erreur, renvoie la paire <true, hashes>
      où hashes contient les données chargées
    - Si le chargement d'un fichier a rencontré une erreur, renvoie le triplet <false, res, fname>
      où "res" indique le type d'erreur (:read_error ou :format_error) et "fname" le nom du fichier causant l'erreur.

    hashes est un dictionnaire contenant des paires <name, data>
    où "name" correspond au nom associé au fichié dans @files, et "data" est un dictionnaire.
    
    Ce dictionnaire lie un identifiant (première valeur présente dans chaque ligne),
    avec un tableau contenant toutes les lignes associées à cet identifiant.
    
    Chaque ligne est elle-même un dictionnaire associant intitulés de colonne avec valeurs.

    Ex: Si le fichier, au nom associé "file name" contient
    c1, c2, c3, c4
    1,  a,  b,  c
    1,  d,  e,  f
    2,  g,  h,  i

    hashes contiendra 
    {"file name" => 
        {
            "1" => [
                {"c1" => "1", "c2"=> "a", "c3" => "b", "c4" => "c"},
                {"c1" => "1", "c2"=> "d", "c3" => "e", "c4" => "f"}
                ]
            "2" => [
                {"c1" => "2", "c2"=> "g", "c3" => "h", "c4" => "i"}
                ]
        }
    }

=end    
    def load()
        @hashes = {}
        @files.each do |f|
            bool, res, fname = load_file(f[:path])
            if(!bool)
                return false, res, fname
            else
                @hashes[f[:name]] = res
            end
        end
        return true, @hashes
    end

private

    def load_file(filename)
        hash_file = {}      

        # Tente d'ouvrir le fichier et de le lire
        begin
            arr_of_arrs = CSV.read(filename)
        rescue => e
            return false, :read_error, filename
        end

        column_names = arr_of_arrs.delete_at(0)

        # Parcour de chaque ligne
        arr_of_arrs.each do |row|

            # Initialise et place le nouveau dictionnaire dans le résultat en fonction de 
            # la valeur de la première colonne.
            hash_row = {}
            if(hash_file[row[0]] == nil)
                hash_file[row[0]] = [hash_row]
            else
                hash_file[row[0]].concat([hash_row])
            end

            # Si le nombre de colonne n'est pas correcte, renvoie une erreur
            if(row.length != column_names.length)
                return false, :format_error, filename
            end

            # Remplis le dictionnaire avec le contenu de la ligne et l'intitulé
            # des colonnes.
            for i in 0..row.length-1 do
                hash_row[column_names[i]] = row [i]
            end

        end
        
        return true, hash_file
    end

end
