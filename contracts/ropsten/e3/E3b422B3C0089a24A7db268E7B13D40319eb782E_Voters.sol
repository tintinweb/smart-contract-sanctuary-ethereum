/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6 <0.9.0;

contract Voters {
    address public admin;
    struct Voter {
        string name;
        string email;
        string signature;
        address account;
    }

    // default to false, when registered, set can turn to login status directly
    mapping(address => bool) public isRegister;

    // the login address => the Voter struct info
    mapping(address => Voter) public voters;

    // voter id => voters address, when want to load all voters
    mapping(uint256 => address) public voterAddress;

    // voter address and their signature, set at verifySignature()
    mapping(address => string) public voterSignature;

    // check if this voter, at this election, has right to vote
    mapping(address => mapping(uint256 => bool)) public canVote;

    // check if this voter, at this election, vote or not
    mapping(address => mapping(uint256 => bool)) public isVoted;

    // total voter
    uint256 public voterCount = 0;

    // use to ensure parameter is not empty
    modifier notEmpty(string memory _name, string memory _email) {
        require(
            keccak256(abi.encodePacked(_name)) !=
                keccak256(abi.encodePacked("")),
            "Cannot be empty Information"
        );
        require(
            keccak256(abi.encodePacked(_email)) !=
                keccak256(abi.encodePacked("")),
            "Cannot be empty Information"
        );
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    event verifySigner(bytes32 message, address signer);

    /**
        createVoter creates a new voter
        :param _name: voter's name
        :param _email: voter's email
        :hashMsg, signature, string sign: use at verifySignature()
     */
    function createVoter(
        string calldata _name,
        string calldata _email,
        bytes32 hashMsg,
        bytes calldata signature,
        string calldata stringSign
    ) external notEmpty(_name, _email) {
        require(isRegister[msg.sender] == false, "Voter registered already.");
        require(
            verifySignature(hashMsg, signature) == msg.sender,
            "This voter's signature is not verified"
        );
        voters[msg.sender] = Voter(_name, _email, stringSign, msg.sender);
        voterSignature[msg.sender] = stringSign;
        isRegister[msg.sender] = true;
        voterAddress[voterCount] = msg.sender;
        voterCount++;
    }

    /**
        editVoter edit the exist voter
        :param _name: voter's name
        :param _email: voter's email
     */
    function editVoter(string calldata _name, string calldata _email)
        external
        notEmpty(_name, _email)
    {
        require(isRegister[msg.sender] == true);
        Voter memory voter = voters[msg.sender];
        voter.name = _name;
        voter.email = _email;
        voters[msg.sender] = voter;
    }

    function setIsVoted(address _voter, uint256 id) public {
        isVoted[_voter][id] = true;
    }

    function setCanVote(uint256 id, address addr) public {
        require(tx.origin == admin);
        canVote[addr][id] = true;
    }

    /**
     * hashMsg - the hashed message that a voter sign
     * byte signature - use to split to r, s and v
     * stringSign - when it is verified, store the signature
     */
    function verifySignature(bytes32 hashMsg, bytes memory signature)
        public
        returns (address)
    {
        bytes32 signedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hashMsg)
        );
        uint8 v;
        bytes32 r;
        bytes32 s;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) v += 27;

        address signer = ecrecover(signedHash, v, r, s);
        emit verifySigner(hashMsg, signer);
        return signer;
    }
}