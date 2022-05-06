contract MyOgr {

     struct Ogrenci{
        string mail;
        address  adres;
        bool deleted;
        bool valited;
        }

    mapping( address => Ogrenci ) ogrenciler;

    uint limit;
    mapping( uint => address ) ogrIndex;

    address owner;
    bool isActive = false;
    uint registeredUser;
    
     constructor (){
           owner =msg.sender;
           limit = 100;
     }

    function isRegistered(address _adres) view public returns(bool) {
            return (ogrenciler[_adres].adres != address(0) && !ogrenciler[_adres].deleted);
    }

     function addOgr(string memory _email) public OnlyActive {
         require(!isRegistered(msg.sender) , "Kayitli Kullanici");
         require(limit>registeredUser , "Limit Doldu");
         registeredUser++;
            ogrenciler[msg.sender] = Ogrenci(_email,msg.sender,false,false);
            ogrIndex[registeredUser]=msg.sender;
     }

     function getOgr(uint _id) view public returns(string memory){
         return (ogrenciler[ogrIndex[_id]].mail);
     }

     function getUserCount() view public returns(uint){
         return (registeredUser);
     }

     function getActive() view public returns(bool){
         return isActive;
     }
     
     function setActive(bool _aktive)  public OnlyOwner {
        isActive = _aktive;
     }

     function delOgr(uint _id)  public OnlyOwner {
         ogrenciler[ ogrIndex[ _id ] ].deleted =true;
         registeredUser--;
     }

     modifier OnlyActive{
        require(isActive, "Contract Aktif Degil");
        _;
    }
     modifier OnlyOwner{
        require(owner == msg.sender, "Sadece Contract Sahibi Yapabilir");
        _;
    }
}