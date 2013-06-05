# encoding: utf-8

class CreatorsController < ApplicationController

=begin

    Variables globales :

    $editable_tree_root : racine d'un arbre (formé d'objets "Node") contenant la version éditable.
    $info_tree_root : racine d'un arbre (formé d'objets "Node") contenant la version actuelle, non éditable.
    $root : module chargé de la DB correspondant à la racine de $editable_tree_root, lorsqu'il y en a un.
    $global_report : rapport contenant toutes les erreurs présentes sur l'arbre.
    
=end

    def index()
        @title = "Edition de programmes"
        $global_report = Report.new()
    end

=begin
        
    Méthode permettant l'initialisation du créateur de programme.
    - Si le sigle "base" n'est pas repris dans la DB, redirige vers la création d'un nouvel ensemble
      qui formera la racine de l'arbre éditable ($editable_tree_root). $root reste nil.
    - Si le sigle "base" est repris dans la DB, $root contient le module chargé correspondant,
      et l'arbre une copie de l'arborescence depuis $root placée dans des objets "Node".

    Paramètres attendus:
        "base" : sigle du programme édité (peut être nouveau ou existant)
        
=end
    def initialize_tree()

        $editable_tree_root = nil
        $info_tree_root = nil
        $root = nil
        $global_report = Report.new()
        
        @title = "Interface d'édition de programme"
        @base = params[:base].to_s.gsub(" ","")
        id = PmoduleObject.id?(@base)

        if(@base == "")

            flash[:error] = "Un sigle doit être spécifié"
            render 'index'

        elsif(id != nil && Pmodule.find(id).mtype == "cours")

            flash[:error] = "#{@base} : ce module n'est pas un ensemble"
            render 'index'

        elsif(id != nil && Pmodule.find(id).status == "archive")

            flash[:error] = "#{@base} : les archives ne peuvent être éditées"
            render 'index'

        else

            if(id == nil)
                # Lance le processus de création d'ensemble
                @is_root = true
                params = {:sigles => @base}
                @ensemble_object = EnsembleObject.new(params)
                new_module
            else
                # Ajoute l'ensemble existant en tant que racine
                r = add_existing_module_to_tree(@base, nil, nil, nil)
                if(!r)
                    flash[:error] = "Impossible de charger le module correspondant à #{@base}"
                else
                    flash[:success] = "Ensemble correctement chargé"
                    update_global_report_legals()
                end
                render 'show'
            end

        end

    end

=begin

    Joue le rôle d'un "new" standard
    Invoquée avant "create", permet de savoir où le module sera ajouté, à quel noeud parent.

    Paramètre attendu:
        "parent" : sigle du parent sélectionné. Si = nil, suppose que c'est la racine qui est créée
        
=end
    def new_module
        @parent = params[:parent].to_s.gsub(" ","")
        if(@ensemble_object == nil) # permet lors de l'initialisation de passer des paramètres par défaut en
                                    # précréant un EnsembleObject
            @ensemble_object = EnsembleObject.new
        end
        @cours_object = CoursObject.new
        @e_report = @ensemble_object.get_report()
        @c_report = @cours_object.get_report()
        @title = "Création de module"
        render 'new_module'
    end

=begin

    Invoquée après "new_module", crée un noeud à partir des arguments. Le noeud est ajouté au noeud contenant
    le module de sigle "parent", et contient un module pouvant être soit nouvellement créé, soit
    chargé depuis la base de donnée (cours ou ensemble). Le contenu du module contenu dans le parent est adapté.

    Paramètres attendus:
        "ensemble_object" : paramètres à utiliser pour créer un nouvel ensemble.
        "cours_object" : paramètres à utiliser pour créer un nouvel ensemble.
        "sigle" : indique le sigle du module à charger en cas de création de noeud contenant un module de la DB.

        "type" : mis à "new" pour indiquer que la création se fait depuis les paramètres "ensemble_object",
                 ou une autre valeur (nil) si la création doit se faire par le chargement du module depuis la DB.

        "annee" : donne l'année permettant d'ajouter l'ensemble en tant que contenu au parent.
        "obligatoire" : contient soit "obligatoire", soit "optionnel", en fonction de si le module à ajouter
                        doit être placé en tant qu'obligatoire ou optionnel dans le contenu du parent.
        "parent" : sigle du parent qui contiendra le nouveau noeud.
        
=end
    def create

        PmoduleObject.adapt_types(params[:ensemble_object])
        PmoduleObject.adapt_types(params[:cours_object])
        annee = params[:annee]
        obligatoire = params[:obligatoire] == "obligatoire"
        type = params[:type]
        
        @parent = params[:parent].to_s.gsub(" ","")
        if(@parent == "") 
            @is_root = true
            @parent = nil 
        end

        sigle = params[:sigle].to_s.gsub(" ","")

        # Cas de la création d'un nouvel ensemble depuis l'interface
        if(type == "new")

            if(params[:cours_object] != nil)
                params[:cours_object][:mtype] = "cours"
                res, report = add_new_module_to_tree(params[:cours_object], annee, obligatoire, @parent)
                @cours_object = VersionManager.create_module(params[:cours_object])
                @ensemble_object = EnsembleObject.new
                @e_report = report
            else
                if(params[:ensemble_object] != nil) 
                    params[:ensemble_object][:mtype] = "ensemble"
                end
                res, report = add_new_module_to_tree(params[:ensemble_object], annee, obligatoire, @parent)
                @ensemble_object = VersionManager.create_module(params[:ensemble_object])
                @cours_object = CoursObject.new
                @c_report = report
            end

            if(!res)
                flash[:error] = "Impossible de créer ce module"
                render 'new_module'
            else
                flash[:success] = "Module correctement ajouté"
                update_global_report(@parent)
                render 'show'
            end

        # Cas du chargement d'un ensemble existant
        else
            r = add_existing_module_to_tree(sigle, @parent, annee, obligatoire)

            if(r == true)
                flash[:success] = "#{sigle} correctement ajouté"
                update_global_report(sigle)
                update_global_report(@parent)
                render 'show'
            else
                if(r == :unknown_sigle)
                    flash[:error] = "Impossible de charger ce module, sigle non reconnu"
                else # r == false
                    flash[:error] = "Impossible de charger cet module, une erreur est survenue"
                end
                @ensemble_object = EnsembleObject.new()
                @cours_object = CoursObject.new()
                @e_report = @ensemble_object.get_report()
                @c_report = @cours_object.get_report()
                render 'new_module'
            end

        end
    end

=begin

    "edit" standard mis à part que l'id est un sigle et non un entier. Cette différence est due 
    au fait que les modules dans l'arbre ne sont pas toujours présents dans la DB et n'ont donc pas
    tous un identifiant id.

    Paramètre attendu :
        "sigle" : sigle du module sujet à édition. 
        
=end
    def edit_module

        @sigle = params[:sigle].to_s.gsub(" ","")

        @titre = "Édition de module"

        # Le premier noeud correspondant au sigle est bon, l'édition se fait sur tout les noeuds de contenu concerné
        p_n_pairs = Tree.find_nodes($editable_tree_root, @sigle)
        
        if(p_n_pairs != :error && !p_n_pairs.empty? )
            p = p_n_pairs[0][0]
            n = p_n_pairs[0][1]

            if(n != nil)
                if(n.data.mtype == "cours")
                    @cours_object = n.data
                    @report = @cours_object.get_report()
                else
                    @ensemble_object = n.data
                    @report = @ensemble_object.get_report
                end
            end

        else
            @ensemble_object = nil
            @report = Report.new()
            flash[:error] = "Un sigle existant doit être spécifié"          
            render 'show'
        end

    end

=begin

    "update" standard mis à part que l'id n'est pas spécifié. Le module à mettre à jour est identifié
    par le sigle "old_sigle"

    Paramètres attendus :
        "ensemble_object" : paramètres à utiliser pour la mise à jour d'un ensemble.
        "cours_object" : paramètres à utiliser pour la mise à jour d'un cours.
        "old_sigle" : sigle actuel du module sujet à modification

    Ainsi que les paramètres suivant, deux par éléments contenus (de sigle <sigle>) dans l'ensemble modifié
        "<sigle>_annee" : donne l'année qui devra être utilisée dans la description du contenu, pour le sigle <sigle>.
        "<sigle>_obligatoire" : donne la valeur du champ "obligatoire" qui devra être utilisée dans la description du contenu, 
                                pour le sigle <sigle>. Contient soit "obligatoire", soit "optionnel".
        
=end
    def update

        old_sigle = params[:old_sigle]
        PmoduleObject.adapt_types(params[:ensemble_object])
        PmoduleObject.adapt_types(params[:cours_object])

        if(params[:ensemble_object] != nil)
            @ensemble_object = EnsembleObject.new(params[:ensemble_object])
        else
            @ensemble_object = nil
        end

        if(params[:cours_object] != nil)
            @cours_object = CoursObject.new(params[:cours_object])
        else
            @cours_object = nil
        end

        annee = params[:annee]
        obligatoire = params[:obligatoire] == "obligatoire"
        
        # Récupération des noeuds contenant l'ensemble concerné
        p_n_pairs = Tree.find_nodes($editable_tree_root, old_sigle) # Le sigle pour la recherche doit être le sigle avant mise à jour

        if(p_n_pairs != :error && !p_n_pairs.empty?)

            node = p_n_pairs[0][1]

            # Sauvegarde du contenu actuel du noeud
            bck =node.data

            # Remplacement du contenu par la nouvelle version
            if(node.data.mtype == "cours")
                node.data = @cours_object
            else
                node.data = @ensemble_object
            end

            # Vérification des contraintes sur les champs de la nouvelle version
            tfcc = TreeFieldConstraintsChecker.new(node, $editable_tree_root)
            r = tfcc.check_all()

            # Remise du contenu initial
            node.data = bck

            # Si contraintes violées, n'applique pas la mise à jour
            if(!r) 
                @report = tfcc.report
                flash[:error] = "Impossible de mettre à jour ce module"
                @sigle = old_sigle # Nécessaire pour que edit renvoie @sigle en tant que old_sigle au prochain essai
                render 'edit_module'

            # Sinon
            else

                # Applique la mise à jour sur tous les contenus de noeuds contenant le module
                p_n_pairs.each do |p, n|
                    if(n.data.mtype == "cours")
                        n.data = @cours_object
                    else
                        n.data = @ensemble_object
                    end
                end

                if(node.data.mtype == "ensemble")
                    # Adapte les champs "annee" et "obligatoire" pour chaque contenu lorsque les paramètres
                    # sont disponibles 
                    new_c = []
                    @ensemble_object.get_content_array.each do |s, a, o|
                        if(params["#{s}_annee"]!=nil && params["#{s}_obligatoire"]!=nil)
                            n_a = params["#{s}_annee"]
                            n_o = params["#{s}_obligatoire"]=="obligatoire"
                            new_c << [s, n_a, n_o]
                        else
                            new_c << [s,a,o]
                        end
                    end
                    @ensemble_object.set_content_array(new_c)
                end

                # met à jour les contenus des parents concernant les sigles 
                p_n_pairs.each do |p, n|
                    if(p!=nil)
                        new_c = []
                        p.data.get_content_array.each do |s, a, o|
                            if(s==old_sigle) 
                                if(@ensemble_object != nil)
                                    new_c << [@ensemble_object.sigles_array[0],a,o] 
                                else
                                    new_c << [@cours_object.sigles_array[0],a,o] 
                                end
                            else
                                new_c << [s,a,o]
                            end
                        end
                        p.data.set_content_array(new_c)

                        # Mise à jour du rapport sur le parent
                        update_global_report(p.data.sigles_array[0])
                    end
                end

                flash[:success] = "Module correctement mis à jour"
                # Mise à jour du rapport sur le noeud changé
                update_global_report(p_n_pairs[0][1].data.sigles_array[0])
                render 'show'
            end

        else

            flash[:error] = "Impossible de mettre à jour ce module, noeud non trouvé dans l'arbre"
            @sigle = old_sigle
            render 'edit_module'

        end
            
    end


=begin

    Supprime un noeud dans l'arbre. Le noeud est identifié par le sigle du module qu'il contient, 
    et celui du module contenu par son parent. Le contenu du parent est adapté.

    Paramètres attendus :
        "sigle" : sigle identifiant le noeud.
        "parent" : sigle identifiant le parent.
        
=end
    def remove()
        parent = params[:parent].to_s.gsub(" ","")
        sigle = params[:sigle].to_s.gsub(" ","")

        if(sigle == "")
            flash[:error] = "Un sigle doit être spécifié"
        elsif(parent =="")
            flash[:error] = "Un parent doit être spécifié"
        else
            r = Tree.remove_node(parent, sigle, $editable_tree_root)
            if(r)
                flash[:success] = "#{sigle} supprimé"
                update_global_report(parent)
            else
                flash[:success] = "Impossible de supprimer ce module"
            end
        end

        render 'show'
    end

=begin

    Sauvegarde toute l'arborescence liée à $editable_tree_root dans la DB, en placant la validité des modules
    à "validite" (version future). Ne se fait que si le $gobal_report est vide ou ne contient que des 
    messages liés aux contraintes légales.

    Paramètre attendu :
        "validite" : validite que prendre chaque module à la sauvegarde. Doit correspondre à une version
                     future obligatoirement
        
=end
    def save_all()

        validite = params[:validite].to_s.gsub(" ","")
        if(validite == "")
            flash[:error] = "Une date de validité doit être précisée (future obligatoirement)"
        elsif(!VersionManager.in_future?(validite.to_i))
            flash[:error] = "La date de validité doit être future"
        else

            validite = validite.to_i
            if($editable_tree_root == nil) 
                flash[:error] = "Aucun programme à sauvegarder"
            elsif($global_report.empty?() || $global_report.categories? == ["( #{$legal_category} )"])

                # Si il existe un autre version future pour ce module, la supprime
                msg = nil

                modules = $editable_tree_root.list
                res = true
                fails = []

                modules.each do |m|
                    m.validite = validite

                    if(remove_existing_version(m, validite))
                        msg = "une version future existante a été replacée"
                    end

                    report = Report.new()
                    r = VersionManager.save(m.extract_params(),report)
                    # Concidère qu'une erreur s'est produite seulement si le module
                    # sujet à erreur n'est pas déjà présent dans la base de donnée,ce qui peut
                    # se produire lorsque le module est présent plusieurs fois dans l'arbre.
                    if(!r &&  PmoduleObject.id?(m.sigles_array[0])==nil)
                        fails << "#{m.sigles_array[0]} : #{report.list.join(', ')}" 
                        res = false
                    end
                end

                if(!res) 
                    flash[:error] = "Impossible de sauvegarder les modules suivants : #{fails.join(',')}"
                    if msg != nil then flash[:error] += " (#{msg})"end
                else
                    flash[:success] = "Programme sauvegardé"
                    if msg != nil then flash[:success] += " (#{msg})"end
                end
                render 'index'
                return
            else
                flash[:error] = "Impossible de sauvegarder le programme, des contraintes autres que légales demeurent insatisfaites"
            end

        end
        
        render 'show'

    end

=begin

    Sauvegarde toute l'arborescence liée à $editable_tree_root dans la DB, en y remplacant la version existante. 
    Ne se fait que si le $gobal_report est vide ou ne contient que des messages liés aux contraintes légales.

    Aucun paramètre attendu
        
=end
    def update_all()
        
        if($editable_tree_root == nil) 
            flash[:error] = "Aucun programme à sauvegarder"
            render 'show'
        elsif(PmoduleObject.id?($editable_tree_root.data.sigles_array[0]) == nil)
            flash[:error] = "Impossible de mettre à jour le programme, aucune version ne correspond dans la base de donnée"
            render 'show'
        elsif($global_report.empty?() || $global_report.categories? == ["( #{$legal_category} )"])
            modules = $editable_tree_root.list
            res = true
            fails = []

            # Archive les modules qui vont être remplacés.
            VersionManager.archive(modules.last.sigles_array[0])

            # Met à jour les modules un a un
            modules.each do |m|
                id = PmoduleObject.id?(m.sigles_array[0])
                report = Report.new()
                # Sauve si module neuf (lorsque sigle changé ou module ajouté), sinon update
                if(id!=nil)
                    # dernier paramètre de update mis à false pour ne pas archiver une seconde fois
                    r = VersionManager.update(id, m.extract_params(), report, false)
                else
                    r = VersionManager.save(m.extract_params(),report)
                end
                if !r then fails << "#{m.sigles_array[0]} : #{report.list.join(', ')}" end
                res &= r
            end

            if(!res) 
                flash[:error] = "Impossible de mettre à jour les modules suivants : " + fails.join(',')
            else
                flash[:success] = "Programme mis à jour. La version précédente a été archivée."
            end
            render 'index'
        else
            flash[:error] = "Impossible de mettre à jour le programme, des contraintes autres que légales demeurent insatisfaites"
            render 'show'
        end

    end

private

    # Ajoute un noeud à l'arbre $editable_tree_root, au noeud parent "parent", contenant un module formé de "params",
    # et sous les caractéristiques "annee" et "obligatoire". Si parent est nil, ajoute le noeud en tant que racine.
    # Renvoie true si l'ajout s'est effectué, false sinon, accompagné d'un rapport.
    def add_new_module_to_tree(params, annee, obligatoire, parent)

        @module = VersionManager.create_module(params)
        new_node = Node.new(@module)
        tfcc = TreeFieldConstraintsChecker.new(new_node, $editable_tree_root)

        if(!tfcc.check_all())
            return false, tfcc.report
        elsif(parent != nil)
            r = add_node_as_content(new_node, parent, annee, obligatoire)
        else
            r = add_new_ensemble_as_roots(new_node) 
        end
        
        return r, Report.new

    end

    # Ajoute un noeud à l'arbre $editable_tree_root, au noeud parent "parent", contenant le module associé au sigle "sigle"
    # et sous les caractéristiques "annee" et "obligatoire". Si parent est nil, ajoute le noeud en tant que racine.
    # Le module ajouté proviens soit de la DB, soit de l'arbre lui-même quand il y existe (pour prendre en compte les 
    # éventuelles modifications apportées)
    # Renvoie true si l'ajout s'est effectué, :unknown_sigle si le sigle ne correspond à aucun module, false sinon.
    def add_existing_module_to_tree(sigle, parent, annee, obligatoire)

        id = PmoduleObject.id?(sigle)
        if(id==nil)
            return :unknown_sigle
        else    

            # Recherche du noeud dans l'arbre
            new_node = Tree.find_node($editable_tree_root, sigle)

            # Si rien trouvé, importe le module et crée un nouveau noeud
            if(new_node == nil || new_node == :error)
                # Création du nouveau noeud
                if(Pmodule.find(id).mtype == "cours")
                    m = CoursObject.new()
                else
                    m = EnsembleObject.new()
                end
                m.load(id)
                new_node = Node.new(m)
            end

            if(parent != nil) 
                r = add_node_as_content(new_node, parent, annee, obligatoire)
            else
                r = add_existing_ensemble_as_roots(id, new_node)    
            end
        
            return r    
        end

    end

    # Ajoute du noeud "node" a tous les noeuds de sigle "parent", sous les caractéristiques
    # "annee" et "obligatoire".
    def add_node_as_content(node, parent, annee, obligatoire)
        
        if node == nil || parent == nil then return nil end

        # Récupération de tous les parents
        p_n_pairs = Tree.find_nodes($editable_tree_root, parent)
        sigle = node.data.sigles_array[0]
        
        if(p_n_pairs != :error && !p_n_pairs.empty?)
            
            # Parcours des parents
            p_n_pairs.each do |p, n|
                parent_node = n

                # Si déjà contenu, considère que l'ajout est un succès
                if(parent_contains?(parent_node, sigle))
                    return true
                end

                # Adaptation du contenu
                c = parent_node.data.get_content_array

                c << [sigle, annee, obligatoire]
                parent_node.data.set_content_array(c)
                
                # Ajout du noeud
                parent_node.add_child(node)
                
                # Complétion de l'arbre récursivement sur le nouveau noeud, si aucune boucle n'est créée
                tscc = TreeStructuralConstraintsChecker.new(node, $editable_tree_root)
                if(tscc.check_loops())
                    Tree.build_tree(node)
                end
            end
            
            return true
        else
            return false
        end

    end

    # Ajoute du noeud "node" en tant que racine $editable_tree_root et charge l'arbre correspondant
    # Charge l'ensemble d'id "id" avant de le placer dans $root (id est supposé faire référence à 
    # l'ensemble contenu dans node).
    # Ajoute une copie de "node" en tant que $info_tree_root et charge l'arbre correspondant une 
    # seconde fois.
    def add_existing_ensemble_as_roots(id, node)
        if node == nil || id == nil then return false end
        
        $editable_tree_root = node  
        Tree.build_tree($editable_tree_root)    

        e = EnsembleObject.new()
        e.update_params(node.data.extract_params)
        $info_tree_root = Node.new(e)
        Tree.build_tree($info_tree_root)    

        $root = EnsembleObject.new()
        $root.load(id)  
        return true
    end

    # Ajoute du noeud "node" en tant que racine  $editable_tree_root, et place $root à nil.
    def add_new_ensemble_as_roots(node)
        if node == nil then return false end
        $editable_tree_root = node  
        Tree.build_tree(node)   
        $root = nil
        return true
    end

    # Supprime du rapport global tout message décrivant le module associé à "sigle" 
    # Inclus ensuite le rapport "report" dans le rapport global, sachant que celui-ci
    # est associé au sigle "sigle".
    def include_report(report, sigle)

        # Réinitialise le rapport global
        bck = $global_report
        $global_report = Report.new()
        
        if(bck != nil)
            # Recopie les éléments qui ne concernent pas le sigle
            bck.categories?.each do |c|
                bck.get_category(c).each do |l|
                    if !l.include?("#{sigle} :")
                        $global_report.write(l, c)
                    end
                end
            end 
        end

        # Ajoute les nouveaux éléments concernant le sigle
        report.categories?.each do |c|
            report.get_category(c).each do |l|
                line = "#{sigle} : #{l}"
                if(!$global_report.list.include?(line))
                    if c == $legal_category then c = "( #{c} )" end
                    $global_report.write(line, c)
                end
            end
        end 

    end

    # Modifie le rapport global en mettant à jour les informations concernant le noeud passé
    # en argument uniquement.
    def update_global_report(target_sigle = nil)

        target_node = Tree.find_node($editable_tree_root, target_sigle)

        if $editable_tree_root == nil then return end
        if(target_node == nil || target_node == :error) 
            update_global_report_for_all() 
            return
        end

        # Check des boucles (départ = la cible)
        tscc = TreeStructuralConstraintsChecker.new(target_node, $editable_tree_root)
        if(!tscc.check_loops())
            include_report(tscc.report, target_node.data.sigles_array[0])
        end

        tlcc = TreeLegalConstraintsChecker.new(target_node, $editable_tree_root)
        tscc = TreeStructuralConstraintsChecker.new(target_node, $editable_tree_root)

        # Check contraintes légales + contraintes sur la structure autre que les boucles
        tlcc.check_all
        tscc.check_credits_children
        tscc.check_strict_credits_on_instance

        report = Report.new
        report.merge(tlcc.report)
        report.merge(tscc.report)
        # inclus même si rapport vide car les informations obsolètes doivent être supprimées
        include_report(report, target_node.data.sigles_array[0])
        
    end

    # Met a jour le rapport depuis les informations concernant chaque noeud de l'arbre
    def update_global_report_for_all()

        if $editable_tree_root == nil then return end

        # Check des boucles (départ = la racine), une seule fois pour tout l'arbre
        tscc = TreeStructuralConstraintsChecker.new($editable_tree_root, $editable_tree_root)
        if(!tscc.check_loops())
            include_report(tscc.report, $editable_tree_root.data.sigles_array[0])
        end

        # Pour chaque noeud
        $editable_tree_root.list_nodes().each do |node|

            tlcc = TreeLegalConstraintsChecker.new(node, $editable_tree_root)
            tscc = TreeStructuralConstraintsChecker.new(node, $editable_tree_root)

            # Check contraintes légales + contraintes sur la structure autre que les boucles 
            # (pas tscc.check_credits_parent car vérifié sur le parent directement lors d'une autre itération)
            if(!tlcc.check_all | !tscc.check_credits_children | !tscc.check_strict_credits_on_instance)
                report = Report.new
                report.merge(tlcc.report)
                report.merge(tscc.report)
                include_report(report, node.data.sigles_array[0])
            end

        end
    end

    # Idem que update_global_report_for_all mais ne vérifie que les contraintes légales.
    def update_global_report_legals()
        if $editable_tree_root == nil then return end

        # Pour chaque noeud
        $editable_tree_root.list_nodes().each do |node|

            tlcc = TreeLegalConstraintsChecker.new(node, $editable_tree_root)
            # Check contraintes légales
            if(!tlcc.check_all)
                report = Report.new
                report.merge(tlcc.report)
                include_report(report, node.data.sigles_array[0])
            end

        end     
    end

    # Cherche une version future existante pour le module m par rapport à validite,
    # la supprime (récursivement) si elle existe.
    def remove_existing_version(mod, validite)

        root_params =  mod.extract_params 
        root_params[:validite] = validite
        adapted_root_params = VersionManager.params_according_to_validity(root_params)
        root_adapted = VersionManager.create_module(adapted_root_params)
        id = PmoduleObject.id?(root_adapted.sigles_array[0])
        if(id != nil)
            eo = EnsembleObject.new()
            eo.load(id)
            eo.destroy_recursively(Report.new)
            return true
        end

        return false

    end

private

    # Renvoie true si le noeud "parent_node" contient le module
    # de sigle "sigle", false sinon.
    def parent_contains?(parent_node, sigle)
        parent_node.data.get_content_array.each do |s, a, o|
            if s == sigle then return true end
        end
        return false
    end

end