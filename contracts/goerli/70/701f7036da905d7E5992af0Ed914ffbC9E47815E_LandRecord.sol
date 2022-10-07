// SPDX-License-Identifier:MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

contract LandRecord {
    uint256 public personCount = 0;
    uint256 public plotCount = 0;
    uint256 public adminCount = 0;
    address public govtGSTAddr;

    constructor(address _govt) public {
        govtGSTAddr = _govt;
    }

    struct Person {
        uint256 personId;
        uint256 perAadharno;
        uint256[] inheritChildren;
    }

    event plotAdded(
        uint256 plotId,
        string plotAddr,
        uint256 price,
        uint256[] owner,
        uint256 times
    );
    event plotSale(
        uint256 plotId,
        bool isSelling,
        uint256[] owner,
        uint256 sellingPrice,
        uint256 times
    );
    event plotForBuy(
        uint256 plotId,
        uint256 newowner,
        uint256 price,
        uint256 times
    );
    event plotTransferred(
        uint256 plotId,
        uint256[] oldowner,
        uint256 newowner,
        uint256 sellPrice,
        uint256 times
    );
    event eventConsensus(
        uint256 plotId,
        address sender,
        bool decision,
        uint256 times
    );

    mapping(uint256 => Person) public personIds;
    mapping(uint256 => Person) public personaadhars;

    struct Plot {
        uint256 plotId;
        string plotaddr;
        uint256 plotprice;
        uint256 taxpercent;
        string typedesc;
        uint256[] owneraadhar;
        bool isSelling;
        uint256 sellingPrice;
        uint256 newowneraadhar;
        string neighbours;
        bool[] consensus;
        string imageurl;
        bool inprocess;
    }

    mapping(uint256 => Plot) public Plots;

    struct Admin {
        uint256 adminId;
        uint256 adminaadharno;
        address adminaddr;
        string role;
    }

    mapping(address => Admin) public Admins;
    mapping(uint256 => address) public AdminIds;
    mapping(uint256 => Admin) public Adminaadhars;

    modifier plotowneroradmin(uint256 plotId, uint256 _aadhar) {
        bool x = false;
        for (uint256 i = 0; i < Plots[plotId].owneraadhar.length; i++) {
            if (Plots[plotId].owneraadhar[i] == _aadhar) {
                x = true;
            }
        }
        if (Admins[msg.sender].adminId != 0) {
            x = true;
        }
        require(x == true);
        _;
    }

    modifier adminonly() {
        require(Admins[msg.sender].adminId != 0);
        _;
    }

    function addPerson(
        uint256 _perAadharno,
        uint256[] calldata _inheritChildren
    ) public adminonly returns (uint256) {
        uint256 x = personaadhars[_perAadharno].personId;
        if (x == 0) {
            Person memory aux;
            personCount++;
            aux.personId = personCount;
            aux.perAadharno = _perAadharno;
            aux.inheritChildren = _inheritChildren;
            personIds[personCount] = aux;
            personaadhars[_perAadharno] = aux;
            return personCount;
        } else {
            Person memory aux = personaadhars[_perAadharno];
            aux.inheritChildren = _inheritChildren;
            personIds[_perAadharno] = aux;
            personaadhars[aux.personId] = aux;
            return personCount;
        }
    }

    function addAdmin(uint256 _adminaadharno, string memory _role)
        public
        returns (uint256)
    {
        uint256 x = Admins[msg.sender].adminId;
        if (x == 0) {
            adminCount++;
            Admin memory aux;
            aux.adminId = adminCount;
            aux.adminaadharno = _adminaadharno;
            aux.adminaddr = msg.sender;
            aux.role = _role;
            Admins[msg.sender] = aux;
            AdminIds[adminCount] = msg.sender;
            Adminaadhars[_adminaadharno] = aux;
            return adminCount;
        } else {
            Admin memory aux = Admins[msg.sender];
            aux.adminaadharno = _adminaadharno;
            aux.role = _role;
            Admins[msg.sender] = aux;
        }
    }

    function addPlot(
        string memory _plotaddr,
        uint256 _plotprice,
        uint256 _taxpercent,
        string memory _typedesc,
        uint256[] memory _owneraadhar,
        string memory _neighbours,
        string memory _imageurl
    ) public returns (uint256) {
        plotCount++;
        Plot memory aux;
        aux.plotId = plotCount;
        aux.plotaddr = _plotaddr;
        aux.plotprice = _plotprice;
        aux.owneraadhar = _owneraadhar;
        aux.taxpercent = _taxpercent;
        aux.typedesc = _typedesc;
        aux.neighbours = _neighbours;
        aux.imageurl = _imageurl;
        aux.inprocess = false;
        Plots[plotCount] = aux;
        emit plotAdded(plotCount, _plotaddr, _plotprice, _owneraadhar, now);
        return plotCount;
    }

    function putForSale(
        uint256 _plotId,
        uint256 _price,
        uint256 _aadhar
    ) public plotowneroradmin(_plotId, _aadhar) {
        Plot memory aux = Plots[_plotId];
        require(aux.inprocess == false);
        aux.isSelling = true;
        aux.sellingPrice = _price;
        Plots[_plotId] = aux;
        emit plotSale(_plotId, true, aux.owneraadhar, _price, now);
    }

    function desale(uint256 _plotId, uint256 _aadhar)
        public
        plotowneroradmin(_plotId, _aadhar)
    {
        Plot memory aux = Plots[_plotId];
        require(aux.inprocess == false);
        aux.isSelling = false;
        aux.sellingPrice = 0;
        Plots[_plotId] = aux;
        emit plotSale(_plotId, false, aux.owneraadhar, 0, now);
    }

    function addTax(uint256 _plotId, uint256 _taxpercent) public {
        Plot memory aux = Plots[_plotId];
        aux.taxpercent = _taxpercent;
        Plots[_plotId] = aux;
    }

    function buyLand(uint256 _plotId, uint256 _aadhar) public {
        Plot memory aux = Plots[_plotId];
        require(aux.inprocess == false);
        aux.newowneraadhar = _aadhar;
        aux.inprocess = true;
        Plots[_plotId] = aux;
        emit plotForBuy(_plotId, _aadhar, aux.sellingPrice, now);
    }

    function consensus(uint256 _plotId, bool _dec) public {
        Plot storage aux = Plots[_plotId];
        Plots[_plotId].consensus.push(_dec); //push true or false in array of boolean
        emit eventConsensus(_plotId, msg.sender, _dec, now);
        uint256 participants = aux.consensus.length; //check for current length of array of boolean
        require(participants <= adminCount);
        if (participants >= ((adminCount / 2) + 1)) {
            //check for more than 50% participants voted or not
            uint256 nostrue;
            for (uint256 i = 0; i < participants; i++) {
                if (aux.consensus[i]) {
                    nostrue++;
                }
            }
            if ((2 * nostrue) >= adminCount) {
                //if more than or equal to 50 % no. of true present // do action
                transfer(_plotId);
            }
        }
    }

    function transfer(uint256 _plotId) private {
        Plot memory aux = Plots[_plotId];
        aux.plotprice = aux.sellingPrice;
        aux.isSelling = false;
        aux.sellingPrice = 0;
        aux.inprocess = false;
        uint256[] memory oldowner = aux.owneraadhar;
        uint256 x = aux.newowneraadhar;
        aux.newowneraadhar = 0;
        Plots[_plotId] = aux;
        delete Plots[_plotId].owneraadhar;
        Plots[_plotId].owneraadhar.push(x);
        plotTransferred(_plotId, oldowner, x, aux.plotprice, now);
    }

    function expirePerson(uint256 _plotId) public {
        uint256[] memory x = Plots[_plotId].owneraadhar;
        Person memory aux = personaadhars[x[0]];
        delete Plots[_plotId].owneraadhar;
        Plots[_plotId].owneraadhar = aux.inheritChildren;
    }

    function getowner(uint256 _plotId) public view returns (uint256[] memory) {
        return Plots[_plotId].owneraadhar;
    }

    function getconsensus(uint256 _plotId) public view returns (bool[] memory) {
        return Plots[_plotId].consensus;
    }
}