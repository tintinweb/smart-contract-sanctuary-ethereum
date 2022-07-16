/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// declare contract
contract SupplierCertification {
    // defines a abstract requirement
    struct Requirement {
        string name;
        string payload;
        bool done;
    }

    // contains all participating addr
    address[] address_registry;

    // saves names of parties
    mapping(address => string) public parties;
    // saves all parties and their corresponding requirements
    mapping(address => mapping(uint256 => Requirement)) public req_map;

    // gets called when contract is deployed
    // sets parties and requirements
    // takes as arguments the addresses and their corresponding names
    constructor(
        address addr_suppl_1,
        string memory name_suppl_1,
        address addr_suppl_2,
        string memory name_suppl_2,
        address addr_suppl_3,
        string memory name_suppl_3
    ) {
        // set cert receiver as contract deployer
        setParty(msg.sender, "cert_receiver");
        _pushReqs(msg.sender);

        // set the suppliers
        setParty(addr_suppl_1, name_suppl_1);
        _pushReqs(addr_suppl_1);
        setParty(addr_suppl_2, name_suppl_2);
        _pushReqs(addr_suppl_2);
        setParty(addr_suppl_3, name_suppl_3);
        _pushReqs(addr_suppl_3);
    }

    // assigns name to given address
    function setParty(address _wallet, string memory party_name) public {
        parties[_wallet] = party_name;
    }

    // view function to retrieve the name of a party involved
    function containsParty(address _wallet)
        public
        view
        returns (string memory)
    {
        return parties[_wallet];
    }

    // view function to show what is requirement 1, 2, 3, etc.
    function getReq(address _wallet, uint256 req_id)
        public
        view
        returns (string memory)
    {
        return req_map[_wallet][req_id].name;
    }

    // predefine the requirements with inital values for a given party
    function _pushReqs(address party) internal {
        req_map[party][1] = Requirement({
            name: "Risk Management",
            payload: "",
            done: false
        });
        req_map[party][2] = Requirement({
            name: "Risk Analysis",
            payload: "",
            done: false
        });
        req_map[party][3] = Requirement({
            name: "Declaration of Principle",
            payload: "",
            done: false
        });
        req_map[party][4] = Requirement({
            name: "Preventative Measures",
            payload: "",
            done: false
        });
        req_map[party][5] = Requirement({
            name: "Remedial Measures",
            payload: "",
            done: false
        });
        req_map[party][6] = Requirement({
            name: "Complaint Procedure",
            payload: "",
            done: false
        });
        req_map[party][7] = Requirement({
            name: "Documentation and Reporting Requirements",
            payload: "",
            done: false
        });

        // s tores the participating addresses in the address registry
        address_registry.push(party);
    }

    // fulfill a requirement
    function fulfillReq(uint256 req_id, string memory payload) public {
        req_map[msg.sender][req_id].payload = payload;
        req_map[msg.sender][req_id].done = true;
    }

    // get the status of a requirement
    function reqDone(address party, uint256 req_id) public view returns (bool) {
        if (req_map[party][req_id].done == true) {
            return true;
        } else {
            return false;
        }
    }

    // get the payload of a requirement
    function inspectReqMapPayload(address party, uint256 req_id)
        public
        view
        returns (string memory)
    {
        if (reqDone(party, req_id)) {
            return req_map[party][req_id].payload;
        } else {
            return "Requirement not fulfilled yet";
        }
    }

    // check if all requirements of all participants are fulfilled
    function allReqsFulfilled() public view returns (bool) {
        for (uint256 i = 0; i < address_registry.length; i++) {
            for (uint256 n = 1; n < 8; n++) {
                if (reqDone(address_registry[i], n) != true) {
                    return false;
                }
            }
        }
        return true;
    }
}