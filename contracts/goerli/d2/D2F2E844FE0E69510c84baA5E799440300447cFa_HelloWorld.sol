// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

import "./mulwallet.sol";
// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Ethereum blockchain. Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract HelloWorld is ERC721 {
      struct Patient {
      uint id;
      string name;
      uint age;
      uint cc;
      uint phone;
      string Allergies;
      string Medication;
      string Hospital;
      address patientAddress;
   }

   Patient[] public patients;

   event NewPatient(uint _id, string _name, uint _age, uint _cc, uint _phone, string _allergies,string _medication,string _hospitalNamePatients, address _address);


   function createPatient(uint256 _id, string memory _name, uint _age, uint _cc, uint _phone, string memory _allergies,string memory _medication,string memory _hospitalNamePatients, address _address) public {
      patients.push(Patient(_id,_name, _age, _cc,_phone,_allergies,_medication,_hospitalNamePatients,_address));
      owners[_id] = _address;
      emit NewPatient(_id,_name,_age,_cc,_phone,_allergies,_medication,_hospitalNamePatients,_address);

   }

   // Função para o paciente permitir que um determinado hospital tenha autorização para transferir
   function patientApproval(address _hosp, uint256 _idpaciente) public{
      require (owners[_idpaciente] == msg.sender);
      auth[_idpaciente] = _hosp;
   }

      // Função para o hospital permitir que uma determinada clinica tenha autorização para ver dados
   function clinicApproval(address _clin, uint256 _idpaciente) public {
      require (auth[_idpaciente] == msg.sender);
      clinicAuth[_idpaciente] = _clin;
   }

   // Função para o paciente permitir que um determinado hospital tenha autorização para transferir
   function patientUnApproval(address _hosp, uint256 _idpaciente) public{
      require (owners[_idpaciente] == msg.sender);
      //auth[_idpaciente] = 0x0;
   }


   function showPatient(uint256 _idpaciente) public returns(string memory){
      require (auth[_idpaciente] == msg.sender || clinicAuth[_idpaciente] == msg.sender, "afafaawfaf");
      //return Patient;
   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

contract ERC721 {
    mapping(address => uint256) internal balances;
    mapping(uint256 => address) internal owners;
    mapping(uint256 => address) internal auth;
    mapping(uint256 => address) internal clinicAuth;
    mapping(address => mapping(address => bool)) private operatorApprovals; // NFT owner => operator => approved or not
    mapping(uint256 => address) private tokenApprovals; // token ID => approved address
    mapping(address => mapping(address => bool)) private pacienteAprova;
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );





    // Finds the owner of an NFT ---- O DONO É SEMPRE O PACIENTE
    function ownerOf(uint256 _tokenId)public view tokenIdExists(_tokenId) returns (address){
        return owners[_tokenId];
    }

    // OPERATOR
    // Enables or disables an operator to manage all of msg.sender's assets
    function setApprovalForAll(address _operator, bool _approved) public {
        operatorApprovals[_operator][msg.sender] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // Checks if an address is an operator for another address
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    // APPROVAL
    // Updates an approved address for an NFT
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Msg.sender is not the owner or an approved operator"
        );
        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    // Gets the approved address for a single NFT
    function getApproved(uint256 _tokenId)public view tokenIdExists(_tokenId)returns (address)
    {
        return tokenApprovals[_tokenId];
    }

    // TRANSFER
    // Transfers ownership of an NFT
    function transferFrom(address _from,address _to,uint256 _tokenId) public tokenIdExists(_tokenId) {
        address owner = ownerOf(_tokenId);
        approve(address(0), _tokenId);


        owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    // Standard transferFrom
    // Check if onERC721Received is implemented WHEN sending to smart contracts
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public {
        transferFrom(_from, _to, _tokenId);
        require(checkOnERC721Received(), "Receiver not implemented");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    // Oversimplified => what would actually do: call the smart contract's onERC721Received function and check if any response is given
    function checkOnERC721Received() private pure returns (bool) {
        return true;
    }

    // EIP165: Query if a contract implements another interface (checks if another smart contract have the functions that are been looked for)
    function supportsInterface(bytes4 _interfaceId)
        public
        pure
        virtual
        returns (bool){
        return _interfaceId == 0x80ac58cd;
    }

    modifier tokenIdExists(uint256 _tokenId) {
        require(owners[_tokenId] != address(0), "TokenId does not exist");
        _;
    }
}