/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract supplychain {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    function changeOwner(address _newOwner)
        public
        onlyOwner
        validAddress(_newOwner)
    {
        owner = _newOwner;
    }

    // ------------- Structs -----------
    struct medStruct {
        string medName;
        string expdate;
        uint256 id;
        uint256 exp;
    }

    struct ManufacturedetailStruct {
        address user;
        string name;
    }
    struct retaildetailStruct {
        address own;
        string name;
    }
    struct DistdetailStruct {
        address dist;
        string name;
    }
    struct userStruct {
        mapping(string => uint24) stock;
        string role;
        string name;
    }
    // ------------- Structs -----------

    // ------------- Mapping -----------
    mapping(uint256 => address) last_accessMapping;
    mapping(uint256 => address) next_accessMapping;
    mapping(uint256 => address) retailerMapping;
    mapping(uint256 => bool) soldMapping;
    mapping(address => userStruct) userDetailMapping;
    mapping(address => bool) manufacturAccessMapping;
    mapping(address => bool) distributerAccessMapping;
    mapping(address => bool) retailerAcessMapping;
    mapping(uint256 => ManufacturedetailStruct) mdMapping;
    mapping(uint256 => retaildetailStruct) rdMapping;
    mapping(uint256 => DistdetailStruct) ddMapping;
    mapping(uint256 => medStruct) medMapping;

    // ------------- Mapping -----------

    // ------------- More Data -----------

    // ------------- More Data -----------

    constructor() {
        owner = msg.sender;
    }

    function setuser(
        string memory _role,
        address _user,
        string memory name
    ) public onlyOwner {
        if (
            uint256(keccak256(abi.encodePacked(_role))) ==
            uint256(keccak256(abi.encodePacked("Manufacturer")))
        ) {
            manufacturAccessMapping[_user] = true;
        } else if (
            uint256(keccak256(abi.encodePacked(_role))) ==
            uint256(keccak256(abi.encodePacked("Distributer")))
        ) {
            distributerAccessMapping[_user] = true;
        } else if (
            uint256(keccak256(abi.encodePacked(_role))) ==
            uint256(keccak256(abi.encodePacked("Retailer")))
        ) {
            retailerAcessMapping[_user] = true;
        } else {
            revert("enter valid role");
        }
        userDetailMapping[_user].role = _role;
        userDetailMapping[_user].name = name;
    }

    function getmed(uint256 _id)
        public
        view
        returns (
            string memory medName,
            string memory mname,
            string memory dname,
            string memory rname,
            bool soldstatus,
            bool expsts,
            string memory expdate
        )
    {
        bool a = false;
        if (block.timestamp >= medMapping[_id].exp) {
            a == true;
        }
        string memory ed = medMapping[_id].expdate;
        return (
            medMapping[_id].medName,
            mdMapping[_id].name,
            ddMapping[_id].name,
            rdMapping[_id].name,
            soldMapping[_id],
            a,
            ed
        );
    }

    function setmed(
        string memory _medName,
        uint256 sid,
        uint256 lid,
        address _to,
        uint256 expiryd,
        string memory expirydate
    ) public {
        require(
            manufacturAccessMapping[msg.sender] == true,
            "Sender is not manufacturer"
        );

        require(
            distributerAccessMapping[_to] == true,
            "Reciever is not valid Distributer"
        );
        medStruct memory medData;
        medData.medName = _medName;
        medData.exp = block.timestamp + expiryd * 1 days;
        medData.expdate = expirydate;

        for (uint256 i = sid; i <= lid; i++) {
            medMapping[i] = medData;
            soldMapping[i] = false;
            mdMapping[i].user = msg.sender;
            mdMapping[i].name = userDetailMapping[msg.sender].name;
            last_accessMapping[i] = msg.sender;
            next_accessMapping[i] = _to;
            userDetailMapping[msg.sender].stock[_medName]++;
        }
    }

    function checkex(uint256 id) public view returns (bool res) {
        if (block.timestamp >= medMapping[id].exp) {
            return false;
        } else {
            return true;
        }
    }

    function acceptdist(
        uint256 sid,
        uint256 lid,
        address _from
    ) public {
        require(
            manufacturAccessMapping[_from] == true,
            "Sender is not manufacturer"
        );
        require(
            distributerAccessMapping[msg.sender] == true,
            "Reciever is distributer"
        );

        for (uint256 i = sid; i <= lid; i++) {
            require(checkex(i) == true, "medicine expired");
            require(
                _from == last_accessMapping[i],
                "medicine came from someone else"
            );
            require(
                msg.sender == next_accessMapping[i],
                "Unauthorized to access this medicine"
            );
            require(soldMapping[i] == false, "medicine already sold");
            last_accessMapping[i] = msg.sender;
            ddMapping[i].dist = msg.sender;
            ddMapping[i].name = userDetailMapping[msg.sender].name;
            userDetailMapping[msg.sender].stock[medMapping[i].medName]++;
            userDetailMapping[_from].stock[medMapping[i].medName]--;
        }
    }

    function decline(
        uint256 sid,
        uint256 lid,
        address _from
    ) public {
        for (uint256 i = sid; i <= lid; i++) {
            require(
                _from == last_accessMapping[i],
                "medicine came from someone else"
            );
            require(
                msg.sender == next_accessMapping[i],
                "Unauthorized to access this medicine"
            );
            require(soldMapping[i] == false, "medicine already sold");
            next_accessMapping[i] = last_accessMapping[i];
            last_accessMapping[i] = msg.sender;
        }
    }

    function setdistdetails(
        address _to,
        uint256 sid,
        uint256 lid
    ) public {
        require(
            distributerAccessMapping[msg.sender] == true,
            "NOt a distributer"
        );
        require(retailerAcessMapping[_to] == true, "Not a retailer");
        for (uint256 i = sid; i <= lid; i++) {
            require(checkex(i) == true, "medicine expired");
            require(
                msg.sender == last_accessMapping[i],
                "Unauthorized to access this medicine"
            );
            require(
                msg.sender == next_accessMapping[i],
                "Unauthorized to access this medicine"
            );
            require(soldMapping[i] == false, "medicine already sold");
            require(
                userDetailMapping[msg.sender].stock[medMapping[i].medName] >= 1,
                "Medicine not in stock"
            );
            next_accessMapping[i] = _to;
        }
    }

    function setretaildetails(
        uint256 sid,
        uint256 lid,
        address _dist
    ) public {
        require(retailerAcessMapping[msg.sender] == true, "Not a retailer");

        for (uint256 i = sid; i <= lid; i++) {
            require(checkex(i) == true, "medicine expired");
            require(
                _dist == last_accessMapping[i],
                "medicine came from someone else"
            );
            require(soldMapping[i] == false, "medicine already sold");
            require(
                msg.sender == next_accessMapping[i],
                "Unauthorized to access this medicine"
            );

            rdMapping[i].own = msg.sender;
            rdMapping[i].name = userDetailMapping[msg.sender].name;
            retailerMapping[i] = msg.sender;
            userDetailMapping[msg.sender].stock[medMapping[i].medName]++;
            userDetailMapping[_dist].stock[medMapping[i].medName]--;
        }
    }

    function sell(uint256 _id) public {
        require(checkex(_id) == true, "medicine expired");
        require(
            retailerMapping[_id] == msg.sender,
            "Unauthorized to access this medicine"
        );

        require(soldMapping[_id] == false, "medicine already sold");
        soldMapping[_id] = true;
        userDetailMapping[msg.sender].stock[medMapping[_id].medName]--;
    }

    function stockcheck(address[] memory readd, string memory medname)
        public
        view
        returns (uint24[] memory st)
    {
        uint24[] memory a = new uint24[](readd.length);
        for (uint24 i = 0; i < readd.length; i++) {
            a[i] = userDetailMapping[readd[i]].stock[medname];
        }
        return a;
    }
}