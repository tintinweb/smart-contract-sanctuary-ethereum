// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title LandLedger
 * @dev Permet d'enregistrer une propriété au registre foncier
 */
contract LandLedger {
    uint256 public registerFee;
    address public minister;
    mapping(address => bool) public landOfficers;
    mapping(uint256 => address) public landLedger;
    mapping(uint256 => address) public landPendingApprovals;

    event LandAddedToPendingLedger(uint256 _lotNumber);

    function initialize(address _minister, uint256 _registerFee) public {
        minister = _minister;
        registerFee = _registerFee;
    }

    /**
     * @dev Permet au ministre d'ajouter un officier foncier en droit d'approuver des demandes d'ajouts au registre
     * @param _add L'adresse de l'officier foncier à ajouter
     */
    function addLandOfficer(address _add) public onlyMinister {
        require(!landOfficers[_add], "Land officer already added");
        landOfficers[_add] = true;
    }

    /**
     * @dev Permet à un citoyen de faire une demande d'ajout au registre
     * @param _lotNumber Le numéro du lot
     */
    function register(uint256 _lotNumber) public payable {
        require(
            msg.value == registerFee,
            "Not enough fund has been provided in order to complete the transaction"
        );
        require(
            landLedger[_lotNumber] == address(0x0),
            "Land is already taken"
        );
        require(
            landPendingApprovals[_lotNumber] == address(0x0),
            "Land is already pending approval"
        );
        landPendingApprovals[_lotNumber] = msg.sender;
        emit LandAddedToPendingLedger(_lotNumber);
    }

    /**
     * @dev Permet à un citoyen de déclarer la vente d'une propriété
     * @param _lotNumber Le numéro du lot
     */
    function unregister(uint256 _lotNumber) public payable {
        require(
            msg.value == registerFee,
            "Not enough fund has been provided in order to complete the transaction"
        );
        require(
            landLedger[_lotNumber] == msg.sender,
            "You are not the actual owner of this lot"
        );
        delete landLedger[_lotNumber];
    }

    /**
     * @dev Permet à un officier foncier d'approuver une demande d'ajout au registre
     * @param _lotNumber Le numéro du lot
     */
    function approve(uint256 _lotNumber) public onlyLandOfficer {
        address new_owner = landPendingApprovals[_lotNumber];
        require(
            new_owner != address(0x0),
            "There is no pending approbation for this lot number"
        );
        delete landPendingApprovals[_lotNumber];
        landLedger[_lotNumber] = new_owner;
    }

    modifier onlyMinister() {
        require(msg.sender == minister, "Only owner can call this function");
        _;
    }

    modifier onlyLandOfficer() {
        require(
            landOfficers[msg.sender],
            "Only land officers can call this function"
        );
        _;
    }
}