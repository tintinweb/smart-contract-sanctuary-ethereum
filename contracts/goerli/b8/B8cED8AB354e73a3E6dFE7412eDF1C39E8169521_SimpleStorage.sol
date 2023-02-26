//SPDX-License-Identifier: MIT
pragma solidity >=0.8.8; //0.8.12 new version of solidity  ^-> su xat bzii Su yokardakini goymasak islanok

contract SimpleStorage {
    //eger bir degiskene bir deger vermezseniz degiskenin degeri her zmn 0 olucaktir
    uint256 favoriteNumber = 0;

    // Mapping bir bilgiyi baska bir bilgiyle eslestirmeye diyebiliriz. {key: value }gibi pythonda
    // Dictionary in pythons
    mapping(string => uint256) public nameToFavoriteNumber;

    struct People {
        uint favoriteNumber;
        string name;
    }

    //Array in solidity => list in Python (mantigiyla calisiyor)
    People[] public people;

    // input almamiza yardimi bolya yani 2 tane bilgi deger alicagimizi burda gosteriyor.
    function store(uint256 _favoreiteNumber) public {
        favoriteNumber = _favoreiteNumber;
    }

    //view ve pure fonksiyonlari sadece bize verilen bilgileri gostermeye yardimci oluyor.
    //ve gas kullanmiyorlar hic bir sekilde

    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    // calldata , memory - girilen bilgilerin gecici sureligine hafizalarinda sakliyorlar
    // calldata - can`t be mofidied. Otherhand memory can be modified.
    function addPerson(string memory _name, uint256 _favoreiteNumber) public {
        //People memory cretaPerson = Poeple({favoriteNumber: _favoreiteNumber, name: _name});
        //su sekildedem olusturup bilyas yeni insani

        // Input ile aldigimiz verileri Poeple arrayine kaydetmemize yardimci oluyor
        people.push(People(_favoreiteNumber, _name)); // People(cretaPerson) suny goymali bir ayni sey

        // Bu kod blogunda biz _name degiskeni girdigmizde bize o kisinin favorite sayisi gosteriyor;
        nameToFavoriteNumber[_name] = _favoreiteNumber;
    }
}