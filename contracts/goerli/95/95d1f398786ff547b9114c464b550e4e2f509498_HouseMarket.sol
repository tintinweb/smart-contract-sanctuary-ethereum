/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

pragma solidity 0.8.7;

contract HouseMarket {
    address admin;
    Kuca[] public kuce;
    mapping(address => Vlasnistvo) public vlasnistvo;

    struct Kuca {
        uint256 id;
        uint cena;
        string adresa;
        bool jeKupljena;
    }

    struct Vlasnistvo {
        uint256 id;
        bool postoji;
    }

    constructor() {
        admin = msg.sender;

        dodajKucu(2, "test1");
        dodajKucu(3, "test2");
    }

    function dodajKucu(uint _cena, string memory _adresa) public {
        require(msg.sender == admin, "Nisi admin");
        uint256 tmp = kuce.length;

        kuce.push(Kuca(tmp, _cena, _adresa, false));
    }

    function kupiKucu(uint256 _id) public payable {
        require(_id < kuce.length, "kuca ne posoji");
        require(!vlasnistvo[msg.sender].postoji, "Vec imas kucu");
        require(!kuce[_id].jeKupljena, "kuca je kupljna");
        require(msg.value >= kuce[_id].cena, "nema dovoljno para");

        vlasnistvo[msg.sender] = Vlasnistvo(_id, true);
        kuce[_id].jeKupljena = true;
    }
}