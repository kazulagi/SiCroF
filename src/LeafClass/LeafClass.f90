module LeafClass
    use, intrinsic :: iso_fortran_env
    use KinematicClass
    use FEMDomainClass
    use PetiClass
    implicit none


    type :: Leaf_
        type(FEMDomain_)    ::  FEMDomain
        real(real64),allocatable ::  LeafSurfaceNode2D(:,:)
        real(real64)             ::  ShapeFactor,Thickness,length,width,center(3)
        real(real64)             ::  MaxThickness,Maxlength,Maxwidth
        real(real64)             ::  center_bottom(3),center_top(3)
        real(real64)             ::  outer_normal_bottom(3),outer_normal_top(3)
        integer(int32)             ::  Division
        type(leaf_),pointer ::  pleaf
        type(Peti_),pointer ::  pPeti
        real(real64)             ::  rot_x = 0.0d0
        real(real64)             ::  rot_y = 0.0d0
        real(real64)             ::  rot_z = 0.0d0
        real(real64)             ::  disp_x = 0.0d0
        real(real64)             ::  disp_y = 0.0d0
        real(real64)             ::  disp_z = 0.0d0
        real(real64)             ::  shaperatio = 0.30d0
        real(real64)             ::  minwidth,minlength,MinThickness

        integer(int32),allocatable  :: I_planeNodeID(:)
        integer(int32),allocatable  :: I_planeElementID(:)
        integer(int32),allocatable  :: II_planeNodeID(:)
        integer(int32),allocatable  :: II_planeElementID(:)
        integer(int32)  :: A_PointNodeID
        integer(int32)  :: B_PointNodeID
        integer(int32)  :: A_PointElementID
        integer(int32)  :: B_PointElementID
        integer(int32)  :: xnum = 10
        integer(int32)  :: ynum = 10
        integer(int32)  :: znum = 10

    contains
        procedure, public :: Init => initLeaf
        procedure, public :: rotate => rotateleaf
        procedure, public :: move => moveleaf
        procedure, public :: connect => connectleaf
        procedure, public :: rescale => rescaleleaf
        procedure, public :: resize => resizeleaf
        procedure, public :: getCoordinate => getCoordinateleaf
        procedure, public :: gmsh => gmshleaf
    end type
contains

! ########################################
    subroutine initLeaf(obj,config,regacy,Thickness,length,width,ShapeFactor,&
        MaxThickness,Maxlength,Maxwidth,rotx,roty,rotz,location)
        class(leaf_),intent(inout) :: obj
        real(real64),optional,intent(in) :: Thickness,length,width,ShapeFactor
        real(real64),optional,intent(in) :: MaxThickness,Maxlength,Maxwidth
        real(real64),optional,intent(in)::  rotx,roty,rotz,location(3)
        logical, optional,intent(in) :: regacy
        character(*),optional,intent(in) :: config
        type(IO_) :: leafconf,f
        character(200) :: fn,conf,line
        integer(int32),allocatable :: buf(:)
        integer(int32) :: id,rmc,n,node_id,node_id2,elemid,blcount,i,j
        real(real64) :: loc(3)

        ! 節を生成するためのスクリプトを開く
        if(.not.present(config) .or. index(config,".json")==0 )then
            ! デフォルトの設定を生成
            print *, "New leaf-configuration >> leafconfig.json"
            call leafconf%open("leafconfig.json")
            write(leafconf%fh,*) '{'
            write(leafconf%fh,*) '   "type": "leaf",'
            write(leafconf%fh,*) '   "minlength": 0.005,'
            write(leafconf%fh,*) '   "minwidth": 0.005,'
            write(leafconf%fh,*) '   "minthickness": 0.0001,'
            write(leafconf%fh,*) '   "maxlength": 0.07,'
            write(leafconf%fh,*) '   "maxwidth": 0.045,'
            write(leafconf%fh,*) '   "maxthickness": 0.001,'
            write(leafconf%fh,*) '   "shaperatio": 0.3,'
            write(leafconf%fh,*) '   "xnum": 10,'
            write(leafconf%fh,*) '   "ynum": 10,'
            write(leafconf%fh,*) '   "znum": 20'
            write(leafconf%fh,*) '}'
            conf="leafconfig.json"
            call leafconf%close()
        else
            conf = trim(config)
        endif
        
        call leafconf%open(trim(conf))
        blcount=0
        do
            read(leafconf%fh,'(a)') line
            print *, trim(line)
            if( adjustl(trim(line))=="{" )then
                blcount=1
                cycle
            endif
            if( adjustl(trim(line))=="}" )then
                exit
            endif
            
            if(blcount==1)then
                
                if(index(line,"type")/=0 .and. index(line,"leaf")==0 )then
                    print *, "ERROR: This config-file is not for leaf"
                    return
                endif
    
                if(index(line,"maxlength")/=0 )then
                    ! 生育ステージ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%maxlength
                endif
    
    
                if(index(line,"maxwidth")/=0 )then
                    ! 種子の長さ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%maxwidth
                endif

                if(index(line,"maxthickness")/=0 )then
                    ! 種子の長さ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%maxthickness
                endif
    
    
                if(index(line,"minlength")/=0 )then
                    ! 生育ステージ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%minlength
                endif
    
                if(index(line,"shaperatio")/=0 )then
                    ! 生育ステージ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%shaperatio
                endif
    
                if(index(line,"minwidth")/=0 )then
                    ! 種子の長さ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%minwidth
                endif
    
                if(index(line,"minthickness")/=0 )then
                    ! 種子の長さ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%minthickness
                endif
    
    
    
                if(index(line,"xnum")/=0 )then
                    ! 種子の長さ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%xnum
                endif
    
    
    
                if(index(line,"ynum")/=0 )then
                    ! 種子の長さ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%ynum
                endif
    
    
    
                if(index(line,"znum")/=0 )then
                    ! 種子の長さ
                    rmc=index(line,",")
                    ! カンマがあれば除く
                    if(rmc /= 0)then
                        line(rmc:rmc)=" "
                    endif
                    id = index(line,":")
                    read(line(id+1:),*) obj%znum
                endif
                cycle
    
            endif
    
        enddo
        call leafconf%close()
    
            
    
        ! グラフ構造とメッシュ構造を生成する。
    
        !
        !           %%%%%%%%%%%%%%%%%%%%%%%%%%%%%  B
        !         %%                        %   %
        !        %%                    %      %%  
        !      %%                 %          %%    
        !     %%            %              %%      
        !     %%      %                  %%        
        !     %%                       %%          
        !   A   %%                  %%            
        !      <I> %%%%%%%%%%%%%%%%                               
    
    
    
        ! メッシュを生成
        call obj%FEMdomain%create(meshtype="rectangular3D",x_num=obj%xnum,y_num=obj%ynum,z_num=obj%znum,&
        x_len=obj%minwidth/2.0d0,y_len=obj%minwidth/2.0d0,z_len=obj%minlength,shaperatio=obj%shaperatio)
        

        ! <I>面に属する要素番号、節点番号、要素座標、節点座標のリストを生成
        obj%I_planeNodeID = obj%FEMdomain%mesh%getNodeList(zmax=0.0d0)
        obj%I_planeElementID = obj%FEMdomain%mesh%getElementList(zmax=0.0d0)
        
        ! <I>面に属する要素番号、節点番号、要素座標、節点座標のリストを生成
        obj%II_planeNodeID = obj%FEMdomain%mesh%getNodeList(zmin=obj%minlength)
        obj%II_planeElementID = obj%FEMdomain%mesh%getElementList(zmin=obj%minlength)
        
        buf   = obj%FEMDomain%mesh%getNodeList(&
            xmin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            xmax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            ymin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            ymax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            zmax=0.0d0)
        obj%A_PointNodeID = buf(1)
    
        buf   = obj%FEMDomain%mesh%getNodeList(&
            xmin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            xmax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            ymin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            ymax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            zmin=obj%minlength)
        obj%B_PointNodeID = buf(1)
        buf    = obj%FEMDomain%mesh%getElementList(&
            xmin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            xmax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            ymin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            ymax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            zmax=0.0d0)
        obj%A_PointElementID = buf(1)
    
        buf    = obj%FEMDomain%mesh%getElementList(&
            xmin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            xmax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%xnum)/2.0d0 ,&
            ymin=obj%minwidth/2.0d0 - obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            ymax=obj%minwidth/2.0d0 + obj%minwidth/dble(obj%ynum)/2.0d0 ,&
            zmin=obj%minlength)
        obj%B_PointElementID = buf(1)
    
        print *, obj%A_PointNodeID
        print *, obj%B_PointNodeID
        print *, obj%A_PointElementID
        print *, obj%B_PointElementID

        call obj%FEMdomain%remove()
        call obj%FEMdomain%create(meshtype="Leaf3D",x_num=obj%xnum,y_num=obj%ynum,z_num=obj%znum,&
        x_len=obj%minwidth/2.0d0,y_len=obj%minthickness/2.0d0,z_len=obj%minlength,shaperatio=obj%shaperatio)
    ! デバッグ用
    !    call f%open("I_phaseNodeID.txt")
    !    do i=1,size(obj%I_planeNodeID)
    !        write(f%fh,*) obj%femdomain%mesh%NodCoord( obj%I_planeNodeID(i) ,:)
    !    enddo
    !    call f%close()
    !
    !    call f%open("II_phaseNodeID.txt")
    !    do i=1,size(obj%II_planeNodeID)
    !        write(f%fh,*) obj%femdomain%mesh%NodCoord( obj%II_planeNodeID(i) ,:)
    !    enddo
    !    call f%close()
    !
    !    call f%open("I_phaseElementID.txt")
    !    do i=1,size(obj%I_planeElementID)
    !        do j=1,size(obj%femdomain%mesh%elemnod,2)
    !            write(f%fh,*) obj%femdomain%mesh%NodCoord( &
    !            obj%femdomain%mesh%elemnod(obj%I_planeElementID(i),j),:)
    !        enddo
    !    enddo
    !    call f%close()
    !
    !    call f%open("II_phaseElementID.txt")
    !    do i=1,size(obj%II_planeElementID)
    !        do j=1,size(obj%femdomain%mesh%elemnod,2)
    !            write(f%fh,*) obj%femdomain%mesh%NodCoord( &
    !            obj%femdomain%mesh%elemnod(obj%II_planeElementID(i),j),:)
    !        enddo
    !    enddo
    !    call f%close()
    !    return
    
        ! Aについて、要素番号、節点番号、要素座標、節点座標のリストを生成
    


        if( present(regacy))then
            if(regacy .eqv. .true.)then
            loc(:)=0.0d0
            if(present(location) )then
                loc(:)=location(:)
            endif
            obj%ShapeFactor = input(default=0.30d0  ,option= ShapeFactor  ) 
            obj%Thickness   = input(default=0.10d0,option= Thickness     )
            obj%length      = input(default=0.10d0,option= length      )
            obj%width       = input(default=0.10d0,option= width)
        
            obj%MaxThickness   = input(default=0.10d0  ,option= MaxThickness     )
            obj%Maxlength      = input(default=10.0d0  ,option= Maxlength      )
            obj%Maxwidth       = input(default=2.0d0   ,option= Maxwidth)
        
            obj%outer_normal_bottom(:)=0.0d0
            obj%outer_normal_bottom(1)=1.0d0
        
            obj%outer_normal_top(:)=0.0d0
            obj%outer_normal_top(1)=1.0d0
        
            ! rotate
            obj%outer_normal_Bottom(:) = Rotation3D(vector=obj%outer_normal_bottom,rotx=rotx,roty=roty,rotz=rotz)
            obj%outer_normal_top(:) = Rotation3D(vector=obj%outer_normal_top,rotx=rotx,roty=roty,rotz=rotz)
        
            obj%center_bottom(:)=loc(:)
            obj%center_top(:) = obj%center_bottom(:) + obj%length*obj%outer_normal_bottom(:)
        endif
    endif
    
    end subroutine 
    ! ########################################
    
    
! ########################################
recursive subroutine rotateleaf(obj,x,y,z,reset)
class(leaf_),intent(inout) :: obj
real(real64),optional,intent(in) :: x,y,z
logical,optional,intent(in) :: reset
real(real64),allocatable :: origin1(:),origin2(:),disp(:)

if(present(reset) )then
    if(reset .eqv. .true.)then
        call obj%femdomain%rotate(-obj%rot_x,-obj%rot_y,-obj%rot_z)
        obj%rot_x = 0.0d0
        obj%rot_y = 0.0d0
        obj%rot_z = 0.0d0
    endif
endif

origin1 = obj%getCoordinate("A")
call obj%femdomain%rotate(x,y,z)
obj%rot_x = obj%rot_x + input(default=0.0d0, option=x)
obj%rot_y = obj%rot_y + input(default=0.0d0, option=y)
obj%rot_z = obj%rot_z + input(default=0.0d0, option=z)
origin2 = obj%getCoordinate("A")
disp = origin1
disp(:) = origin1(:) - origin2(:)
call obj%femdomain%move(x=disp(1),y=disp(2),z=disp(3) )


end subroutine
! ########################################


! ########################################
recursive subroutine moveleaf(obj,x,y,z,reset)
class(leaf_),intent(inout) :: obj
real(real64),optional,intent(in) :: x,y,z
logical,optional,intent(in) :: reset
real(real64),allocatable :: origin1(:),origin2(:),disp(:)

if(present(reset) )then
    if(reset .eqv. .true.)then
        call obj%femdomain%move(-obj%disp_x,-obj%disp_y,-obj%disp_z)
        obj%disp_x = 0.0d0
        obj%disp_y = 0.0d0
        obj%disp_z = 0.0d0
    endif
endif

call obj%femdomain%move(x,y,z)
obj%disp_x = obj%disp_x + input(default=0.0d0, option=x)
obj%disp_y = obj%disp_y + input(default=0.0d0, option=y)
obj%disp_z = obj%disp_z + input(default=0.0d0, option=z)

end subroutine
! ########################################

subroutine connectleaf(obj,direct,leaf)
class(leaf_),intent(inout) :: obj,leaf
character(2),intent(in) :: direct
real(real64),allocatable :: x1(:),x2(:),disp(:)

if(direct=="->" .or. direct=="=>")then
    ! move obj to connect leaf (leaf is not moved.)
    x1 =  obj%getCoordinate("A")
    x2 = leaf%getCoordinate("B")
    disp = x2 - x1
    call obj%move(x=disp(1),y=disp(2),z=disp(3) )
endif


if(direct=="<-" .or. direct=="<=")then
    ! move obj to connect leaf (leaf is not moved.)
    x1 = leaf%getCoordinate("A")
    x2 =  obj%getCoordinate("B")
    disp = x2 - x1
    call leaf%move(x=disp(1),y=disp(2),z=disp(3) )
endif
end subroutine


! ########################################
function getCoordinateleaf(obj,nodetype) result(ret)
class(leaf_),intent(inout) :: obj
character(*),intent(in) :: nodetype
real(real64),allocatable :: ret(:)
integer(int32) :: dimnum

dimnum = size(obj%femdomain%mesh%nodcoord,2)
allocate(ret(dimnum) )
if( trim(nodetype)=="A" .or. trim(nodetype)=="a")then
    ret = obj%femdomain%mesh%nodcoord(obj%A_PointNodeID,:)
endif
if( trim(nodetype)=="B" .or. trim(nodetype)=="B")then
    ret = obj%femdomain%mesh%nodcoord(obj%B_PointNodeID,:)
endif

end function
! ########################################

! ########################################
subroutine gmshleaf(obj,name)
class(leaf_),intent(inout) :: obj
character(*),intent(in) ::name

call obj%femdomain%gmsh(Name=name)
end subroutine
! ########################################

! ########################################
subroutine resizeleaf(obj,x,y,z)
    class(Leaf_),optional,intent(inout) :: obj
    real(real64),optional,intent(in) :: x,y,z
    real(real64),allocatable :: origin1(:), origin2(:),disp(:)

    origin1 = obj%getCoordinate("A")
    call obj%femdomain%resize(x_len=x,y_len=y,z_len=z)
    origin2 = obj%getCoordinate("A")
    disp = origin1 - origin2
    call obj%move(x=disp(1),y=disp(2),z=disp(3) )
end subroutine
! ########################################

! ########################################
subroutine rescaleleaf(obj,x,y,z)
    class(Leaf_),optional,intent(inout) :: obj
    real(real64),optional,intent(in) :: x,y,z
    real(real64),allocatable :: origin1(:), origin2(:),disp(:)

    origin1 = obj%getCoordinate("A")
    call obj%femdomain%resize(x_rate=x,y_rate=y,z_rate=z)
    origin2 = obj%getCoordinate("A")
    disp = origin1 - origin2
    call obj%move(x=disp(1),y=disp(2),z=disp(3) )
end subroutine
! ########################################


end module 