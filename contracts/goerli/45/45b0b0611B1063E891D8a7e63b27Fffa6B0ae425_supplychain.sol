// SPDX-License-Identifier: GPL-3.0
//0x5B38Da6a701c568545dCfcB03FcB875f56beddC4 Manufacturer
//0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 Distributer - setdistDetails
//0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db Retailer  - setretailsdetails
//0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
pragma solidity ^0.8.7;

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
    /**
    This mapping indicates if the declined medicine is rejected by the manufacturer.
     */
    mapping(uint256 => bool) public isValid;

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

            //dev-> set true for fresh medicine
            isValid[i] = true;
        }
    }

    function checkex(uint256 id) public view returns (bool res) {
        if (block.timestamp >= medMapping[id].exp) {
            return false;
        } else {
            return true;
        }
    }

    /**
    dev-> A function to check weather the medicine is declined (i.e, isValid) or not.
     */
    function isValidCall(uint256 _id) public view returns (bool valid) {
        return isValid[_id];
    }

    /**
    dev-> A function to accept the declined medicine. It will be called by distributer and manufacturer.
     */

    function acceptDeclined(
        uint256 sid,
        uint256 lid,
        address _from,
        address _to
    ) public {
        //retailer cannot accept declined medicine.
        require(
            retailerAcessMapping[msg.sender] != true,
            "Sender is a Retailer"
        );
        if (distributerAccessMapping[msg.sender] == true) {
            require(
                retailerAcessMapping[_from] == true,
                "Not the retailer who rejected medicine."
            );
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
                require(
                    next_accessMapping[i] == msg.sender,
                    "Medicine is not declined for this distributor"
                );
                next_accessMapping[i] = _to;
                last_accessMapping[i] = msg.sender;
            }
        }

        if (manufacturAccessMapping[msg.sender] == true) {
            require(
                distributerAccessMapping[_from] == true,
                "Not the distributer who rejected medicine."
            );
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
                require(
                    next_accessMapping[i] == msg.sender,
                    "Medicine is not declined for this manufacturer"
                );

                //dev-> manufacturer marked this medicine as invalid.
                isValid[i] = false;
                next_accessMapping[i] = _to;
                last_accessMapping[i] = msg.sender;
            }
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
            //dev-> check weather the medicine is declined (i.e, isValid) or not.
            require(isValid[i] == true, "medicine is rejected by manufaturer");
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
            //dev-> check weather the medicine is declined (i.e, isValid) or not.
            require(isValid[i] == true, "medicine is rejected by manufaturer");
            require(checkex(i) == true, "medicine expired");
            // require(
            //     msg.sender == last_accessMapping[i],
            //     "Unauthorized to access this medicine"
            // );
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
            last_accessMapping[i] = msg.sender;
        }
    }

    function setretaildetails(
        uint256 sid,
        uint256 lid,
        address _dist
    ) public {
        require(retailerAcessMapping[msg.sender] == true, "Not a retailer");

        for (uint256 i = sid; i <= lid; i++) {
            //dev-> check weather the medicine is declined (i.e, isValid) or not.
            require(isValid[i] == true, "medicine is rejected by manufaturer");
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
        //dev-> check weather the medicine is declined (i.e, isValid) or not.
        require(isValid[_id] == true, "medicine is rejected by manufaturer");
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

    function medResell(
        uint256 _id,
        string memory _medName,
        uint256 sid,
        uint256 lid,
        address _to,
        uint256 expiryd,
        string memory expirydate
    ) public {
        if (_id == 1) {
            setmed(_medName, sid, lid, _to, expiryd, expirydate);
        }
        if (_id == 2) {}
    }
}