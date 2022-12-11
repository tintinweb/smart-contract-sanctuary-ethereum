/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: GPL-3.0

/// @title Contract that allow reduction cards selling system
/// @author 5BLOC - SUPINFO 2022
/// @notice It will allow you to buy reductions cards to pay your bus/metro/train tickets cheaper

pragma solidity >=0.7.0 <0.9.0;

contract DiscountCards {
    struct DiscountCard {
        uint256 id;
        string name;
        uint256 discountPercent;
        bool available;
        address owner;
        uint256 price;
        string description;
        string image_url;
    }

    // Le mapping des cartes de réduction, indexées par leur identifiant unique
    mapping(uint256 => DiscountCard) public discountCards;
    // Le mapping des admins, indexées par leur adresse
    mapping(address => bool) public admins;

    // Le compteur d'identifiants pour les nouvelles cartes de réduction
    uint256 public cardCounter = 0;
    // Adresse de l'owner du contrat
    address public contract_owner;

    // Logs en cas d'édition des admins, de création, achat, vente et transfert de cartes
    event adminEdit(address user, string action);
    event cardCreate(
        uint256 id,
        address user,
        uint256 price,
        uint256 reduction
    );
    event cardBuySell(uint256 id, string action, address user, uint256 price);
    event cardTransfer(uint256 id, address sender, address receiver);

    /**
     * @dev Create contract, set contract owner and set it admin
     */
    constructor() {
        //Super admin and admin set
        contract_owner = msg.sender;
        admin_set(contract_owner);

        addDiscountCard("NULLCARD", 0, 0, "EMPTY", "EMPTY");
        discountCards[0].available = false;
    }

    // Ajoute une nouvelle carte de réduction
    /**
     * @dev Crée une carte de reduction
     * @param _name Card name
     * @param _discountPercent Card dicsount percentage
     * @param _price Card price
     * @param _description Card Description
     * @param _image_url Card Image URL
     */
    function addDiscountCard(
        string memory _name,
        uint256 _discountPercent,
        uint256 _price,
        string memory _description,
        string memory _image_url
    ) public {
        // Prérequis: être admin, reduct <= 100 and >= 0
        require(admins[msg.sender], "Only admin can create cards");
        require(_discountPercent <= 100, "Can't be more than 100% reduct.");
        require(_discountPercent >= 0, "Can't be less than 0% reduct.");

        //Création de la carte, ajout dans la liste des cartes et logs
        cardCounter++;
        discountCards[cardCounter] = DiscountCard(
            cardCounter,
            _name,
            _discountPercent,
            true,
            address(0),
            _price,
            _description,
            _image_url
        );

        emit cardCreate(cardCounter, msg.sender, _price, _discountPercent);
    }

    // Achête une carte de réduction disponible
    /**
     * @dev Achète une carte de reduction
     * @param _cardId Identifiant de la carte
     */
    function buyDiscountCard(uint256 _cardId) public payable {
        // Vérifie que la carte existe et qu'elle est encore disponible
        require(
            discountCards[_cardId].available,
            "Cette carte n'est plus disponible"
        );

        // Vérifie si le bon montant à été envoyé
        require(
            msg.value == discountCards[_cardId].price,
            "Insufficient funds"
        );

        // Paiement de la carte au contract owner
        (bool sent, bytes memory data) = contract_owner.call{
            value: discountCards[_cardId].price
        }("");
        require(sent, "Failed to buy card");
        data = "";

        // Marque la carte comme étant vendue et la transfert au nouveau propriétaire
        discountCards[_cardId].available = false;
        discountCards[_cardId].owner = msg.sender;

        // Logs d'achat de carte
        emit cardBuySell(
            _cardId,
            "buy",
            msg.sender,
            discountCards[_cardId].price
        );
    }

    // Transfert d'une carte
    /**
     * @dev Transfert d'une carte de reduction
     * @param _cardId Identifiant de la carte
     * @param _toAddress Adresse à laquelle envoyer la carte
     */
    function transferDiscountCard(uint256 _cardId, address _toAddress) public {
        // Requirement: être proriétaire de la carte pour l'envoyer
        require(
            discountCards[_cardId].owner == msg.sender,
            "You need to own this card to transfer it"
        );

        // S'assurer que l'addresse d'envoi est valide
        require(_toAddress != address(0), "Address not valid");

        // Transfert la carte et la rends non dispo (en cas de carte mise en vente avant le transfert)
        discountCards[_cardId].owner = _toAddress;
        discountCards[_cardId].available = false;

        // Logs
        emit cardTransfer(_cardId, msg.sender, _toAddress);
    }

    // Mise en vente d'une carte
    /**
     * @dev Mets en vente une carte de reduction
     * @param _cardId Identifiant de la carte
     * @param _cardPrice Prix auquel mettre la carte en vente
     */
    function putCardToSell(uint256 _cardId, uint256 _cardPrice) public {
        // Requirement: être propriétaire de la carte
        require(
            discountCards[_cardId].owner == msg.sender,
            "You need to own this card to put it to sell"
        );

        // Rends la carte dispo à la vente avec son prix
        discountCards[_cardId].available = true;
        discountCards[_cardId].price = _cardPrice;

        // Logs
        emit cardBuySell(_cardId, "sell", msg.sender, _cardPrice);
    }

    // Liste toutes les cartes dispo
    /**
     * @dev Liste toutes les cartes disponibles à l'achat
     */
    function listAvailableCards() public view returns (uint256[] memory) {
        uint256 _arraySize = 0;

        // Définition du nombre de cartes dispo (création du tableau à taille fixe)
        for (uint256 i = 0; i <= cardCounter; i++) {
            if (discountCards[i].available) {
                _arraySize++;
            }
        }

        // Création du tableau
        uint256[] memory _cardList = new uint256[](_arraySize);

        _arraySize = 0;

        // Remplissage du tableau
        for (uint256 i = 0; i <= cardCounter; i++) {
            if (discountCards[i].available) {
                _cardList[_arraySize] = i;
                _arraySize++;
            }
        }

        return _cardList;
    }

    // Liste les cartes d'un utilisateur
    /**
     * @dev  Liste toutes les cartes d'un utilisateur
     * @param _userAddress Adresse de l'utilisateur à vérifier
     */
    function listUserCards(address _userAddress)
        public
        view
        returns (uint256[] memory)
    {
        uint256 _arraySize = 0;

        // Définition du nombre de cartes dispo (création du tableau à taille fixe)

        for (uint256 i = 0; i <= cardCounter; i++) {
            if (discountCards[i].owner == _userAddress) {
                _arraySize++;
            }
        }

        // Création et remplissage du tableau
        uint256[] memory _cardList = new uint256[](_arraySize);
        _arraySize = 0;

        for (uint256 i = 0; i <= cardCounter; i++) {
            if (discountCards[i].owner == _userAddress) {
                _cardList[_arraySize] = i;
                _arraySize++;
            }
        }

        return _cardList;
    }

    // Retourne la plus grosse carte de l'utilisateur
    /**
     * @dev Récupère la carte avec le plus haut niveau de reduction
     * @param _userAddress Adresse de l'utilisateur en question
     */
    function getBiggestCard(address _userAddress)
        public
        view
        returns (DiscountCard memory)
    {
        uint256[] memory userCards = listUserCards(_userAddress);
        DiscountCard memory bestCard;
        if (userCards.length == 0) {
            bestCard = discountCards[0];
        } else {
            bestCard = discountCards[userCards[0]];
        }
        // Parcours des cartes de l'utilisateur pour vérifier la plus grosse reduction
        for (uint256 i = 0; i < userCards.length; i++) {
            if (
                discountCards[userCards[i]].discountPercent >
                bestCard.discountPercent
            ) {
                bestCard = discountCards[userCards[i]];
            }
        }
        return bestCard;
    }

    // Retourne la plus grosse reduction de l'utilisateur
    /**
     * @dev Récupère la carte avec le plus haut niveau de reduction et retourne son %
     * @param _userAddress Adresse de l'utilisateur en question
     */
    function getBiggestReduct(address _userAddress)
        external
        view
        returns (uint256)
    {
        DiscountCard memory bestCard = getBiggestCard(_userAddress);

        return bestCard.discountPercent;
    }

    /**
     * @dev Set a user admin
     * @param _user user address who will become admin (require to be owner to play)
     */
    function admin_set(address _user) public {
        require(
            msg.sender == contract_owner,
            "You need to be owner to set a new admin"
        );
        admins[_user] = true;
        emit adminEdit(_user, "set");
    }

    /**
     * @dev Revoke user admin power
     * @param _user user address who admin power will be revoked (require to be owner to play)
     */
    function admin_revoke(address _user) public {
        require(
            msg.sender == contract_owner,
            "You need to be owner to revoke an existing admin"
        );
        admins[_user] = false;
        emit adminEdit(_user, "revoke");
    }
}

contract Tickets {
    address public contract_owner;
    address public card_contract_address;
    uint256 public ticket_price;

    mapping(address => bool) public admins;
    mapping(address => uint256) public tickets;

    event ticketBuy(address user, uint256 amount);
    event ticketUse(address user, uint256 amount);
    event adminEdit(address user, string action);

    /**
     * @dev Create a "ticket selling machine"
     * @param base_price default price for tickets (in gwei)
     * @param cardContract address of the card contract
     */
    constructor(uint256 base_price, address cardContract) {
        contract_owner = msg.sender;
        admin_set(contract_owner);
        ticket_price = base_price * 10e8;
        card_contract_address = cardContract;
    }

    /**
     * @dev Set a user admin
     * @param _user user address who will become admin (require to be owner to play)
     */
    function admin_set(address _user) public {
        require(
            msg.sender == contract_owner,
            "You need to be owner to set a new admin"
        );
        admins[_user] = true;
        emit adminEdit(_user, "set");
    }

    /**
     * @dev Revoke user admin power
     * @param _user user address who admin power will be revoked (require to be owner to play)
     */
    function admin_revoke(address _user) public {
        require(
            msg.sender == contract_owner,
            "You need to be owner to revoke an existing admin"
        );
        admins[_user] = false;
        emit adminEdit(_user, "revoke");
    }

    /**
     * @dev Buy a ticket
     * @param _amount number of tickets wanted, require exact value as msg.value
     */
    function ticket_buy(uint256 _amount) external payable {
        uint256 order_value = calculate_ticket_price(_amount);

        require(msg.value == order_value, "Need to send exact amount of ETH");

        (bool sent, bytes memory data) = contract_owner.call{
            value: order_value
        }("");
        require(sent, "Failed to send Tickets");
        data = data;
        tickets[msg.sender] += _amount;

        emit ticketBuy(msg.sender, _amount);
    }

    /**
     * @dev Get ticket price
     * @param _amount number of tickets wanted, require exact value as msg.value
     */
    function calculate_ticket_price(uint256 _amount)
        public
        view
        returns (uint256)
    {
        DiscountCards card_contract = DiscountCards(card_contract_address);
        uint256 user_best_reduction = card_contract.getBiggestReduct(
            msg.sender
        );

        uint256 base_price = _amount * ticket_price * 100;

        uint256 final_price;
        if (user_best_reduction > 0) {
            final_price = (base_price * user_best_reduction) / (10**(2**2));
        } else {
            final_price = base_price;
        }
        return final_price;
    }

    /**
     * @dev Use a ticket
     * @param _amount amount of ticket to use for defined user
     * @param _user user which tickets will be used
     */
    function ticket_use(uint256 _amount, address _user) public {
        require(admins[msg.sender], "You need to be admin to use tickets");
        require(
            tickets[_user] >= _amount,
            "User don't have enough tickets left"
        );
        tickets[_user] -= _amount;
        emit ticketUse(_user, _amount);
    }
}