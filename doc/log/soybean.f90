program main
    use FarmClass
    implicit none

    type(Farm_):: SoybeanField
    
    call SoybeanField%sowing(crop_name="soybean",single=.false.)
    call SoybeanField%export(FilePath="/home/haruka/test/soybean")

end program 