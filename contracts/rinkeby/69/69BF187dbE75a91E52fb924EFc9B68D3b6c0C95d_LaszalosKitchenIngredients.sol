/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
} library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

} interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
} abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
} interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
} interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
} interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
} contract CommonConstants {
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81;
} contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;
    constructor(string memory uri_) {
        _setURI(uri_);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
} abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
} library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
        counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
    counter._value = value - 1;
    }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
} interface PIZZANFT{
    struct Pizzas {
        address from;
        uint256 _pizzaId;
        uint256 base;
        uint256 sauce;
        uint256 cheese;
        uint256[] meats;
        uint256[] toppings;
        bool isRandom;
        bool unbaked;
        bool calculated;
        uint256 rarity;
    }
    function buyAndBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings) external;
    function randomBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings) external;
    function bakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings) external;
    function unbakePizza(uint256 _pizzaId) external;
    function rebakePizza(uint256 _pizzaId, string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings) external;
    function getTotalPizzas() external returns(uint256);
    function getPizzasIds() external returns(uint256[] memory);
    function getPizzaDetails(uint256 pizzaId) external returns(Pizzas memory);
    function updatePizzaList(uint256 pizzaId, address from, uint256 _pizzaId, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings, bool isRandom, bool unbaked, bool calculated, uint256 rarity) external;
    function getNewPizzas() external returns (bool);
    function setNewPizzas(bool nP) external;

} contract LaszalosKitchenIngredients is ERC1155, Ownable{
    
    address pizzaNFTAddress;
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    uint ARTIST_SHARE = 10;
    uint RARITY_REWARD_SHARE = 1;

    Counters.Counter private _IngredientIds;
    Counters.Counter private _nftIds;

    bool public randomBakePizzaAvailable = false;
    bool public bakePizzaAvailable = false;
    bool public buyAndBakePizzaAvailable = false;
    bool public unbakePizzaAvailable = false;
    bool public rebakePizzaAvailable  = false;

    uint256 totalIngredients;
    uint256 [] meatIngredients;
    uint256 [] toppingIngredients;
    uint256 totalClaimable = 0;
    address developerFundWallet;
    uint256 hundered = 100;
    uint256 totalRarityRewards = 0;

    event createIngredientEvent( uint256 indexed _ingredientId, string ingredientTokenURI, uint256 price, address artist, uint256 ingType);
    event mintIngredients( uint[] mintedIds);

    modifier pizzaTypeAvailableValidation(uint pizzaType) {
        if(pizzaType == 1) {
            require (randomBakePizzaAvailable, "1");
            _;
        }
        else if(pizzaType == 2) {
            require (bakePizzaAvailable, "2");
            _;
        }
        else if(pizzaType == 3) {
            require (buyAndBakePizzaAvailable, "3");
            _;
        }
        else if(pizzaType == 4) {
            require (unbakePizzaAvailable, "4");
            _;
        }
        else if(pizzaType == 5) {
            require (rebakePizzaAvailable, "5");
            _;
        }
    }

    struct UserIngredients {
        uint256 _ingredientId;
        uint256 _nftId;
        address user;
        bool isUsed;
    }

    struct Ingredients {
        string name;
        uint256 _ingredientId;
        string metadata;
        uint256 price;
        uint256 created;
        address artist;
        uint256 ingType;
        uint256 totalCount;
    }

    struct RarityReward {
        address wallet;
        bool claimed;
        uint256 rewardPrice;
        uint256 price;
        uint256 nftId;
        uint256 rarityScore;
    }

    struct IngredientCountResponse {
        uint256 total;
        uint256 minted;
    }

    struct IngredientResponse {
        string name;
        uint256 rarity;
        uint256 usedIn;
    }

    // structs to reduce the number of variables
    struct IngredientsInfo {
        uint256 baseR;
        uint256 sauceR;
        uint256 cheeseR;
        uint256[] meatsR;
        uint256[] toppingsR;
    }
    struct CalculateRarityVars {
        uint256 pizzaId;
        address pizzaOwner;
        uint256 ingId;
        uint256[] meats;
        uint256[] toppings;
        uint256 totalPizzas;
        uint256[] pizzaIds;
        bool ingAvailable;
        uint256 totalIngredientsNow;
        uint256 lowestRarity;
        uint256 lowestRarityId;
        uint256 rarityTotal;
    }

    mapping(uint256 => UserIngredients) userIngredientsList; // ingredientid => UserIngredients
    mapping(uint256 => uint256) mintIngredientTypes; // autoIcrement => ingredientType
    mapping(address => uint256) claimableList; // address => claimableAmount
    mapping(uint256 => uint256) ingredientMintCount; // ingredientId => totalMinted
    mapping(uint256 => Ingredients) ingredientsList; // autoIncrementNumber => Ingredients
    mapping(uint256 => uint256) ingredientTypes; // ingredientId => type
    mapping(uint256 => uint256) ingredientTotalCount; // ingredientId => totalAllowedCount
    mapping(uint256 => uint256) userIngToIngIds; // ingredientMintedId => ingredientOriginalId 
    mapping(uint256 => uint256) ingredientUsedCount; // ingredientId => ingredientCountInPizza
    mapping(address => uint256[]) rarityRewardOwnerIds;
    mapping(uint256 => RarityReward) rarityRewardsList; 
    mapping(uint256 => uint256) ingredientRarityPercent; 
    mapping(uint256 => uint256) rarityRewardsIds;

    // constructor 
    constructor(address pizzaNFTAddr) ERC1155("Laszalos Kitchen Ingredients") {
        pizzaNFTAddress = pizzaNFTAddr;
    }

    // creating the pizzaNft objects to call its functions
    PIZZANFT pizzaNft = PIZZANFT(pizzaNFTAddress);

    function getRarityRewardPizza(uint256 pizzaId) public view returns(RarityReward memory) {
        RarityReward memory rarityReward = rarityRewardsList[pizzaId];
        return rarityReward;
    }

    function getTotalRarityRewards() public view returns(uint256) {
        return totalRarityRewards;
    }

    function getRarityRewardId(uint256 index) public view returns(uint256) {
        return rarityRewardsIds[index];
    }

    // trait rarity
    function traitRarity() internal {
        uint256 totalPizzas = pizzaNft.getTotalPizzas();
        if(totalPizzas > 0) {
            uint256 sauceUsed = 0;
            uint256 cheeseUsed = 0;
            for(uint256 i = 1; i <= totalIngredients; i++) {
                Ingredients memory ingredientDetail = ingredientsList[i];
                uint256 ingredientId = ingredientDetail._ingredientId;
                uint256 count = ingredientUsedCount[ingredientId];
                if(ingredientDetail.ingType == 2 && count > 0) {
                    sauceUsed = sauceUsed + count;
                }
                if(ingredientDetail.ingType == 3 && count > 0) {
                    cheeseUsed = cheeseUsed + count;
                }
                if(count > 0) {
                    ingredientRarityPercent[ingredientDetail._ingredientId] = ingredientUsedCount[ingredientId].mul(100).div(totalPizzas);
                }
                else {
                    ingredientRarityPercent[ingredientDetail._ingredientId] = 0;
                }
            }
            if(sauceUsed> 0) {
                ingredientRarityPercent[5000] = hundered.sub(sauceUsed.mul(100).div(totalPizzas)); // percentage for sauce not used
            }
            if(cheeseUsed > 0) {
                ingredientRarityPercent[5001] = hundered.sub(cheeseUsed.mul(100).div(totalPizzas)); // percentage for cheese not used
            }
        }
        else {
            for(uint256 i = 1; i <= totalIngredients; i++) {
                Ingredients memory ingredientDetail = ingredientsList[i];
                uint256 ingredientId = ingredientDetail._ingredientId;
                ingredientRarityPercent[ingredientId] = 0;
            }
            ingredientRarityPercent[5000] = 0;
            ingredientRarityPercent[5001] = 0;
        }
    }

    // calculate Rarity 
    function calculateRarity() internal {
       
        CalculateRarityVars memory variables;
        // uint256 totalPizzas = pizzaNft.getTotalPizzas();
        variables.totalPizzas = pizzaNft.getTotalPizzas();
        // uint256[] memory pizzaIds = pizzaNft.getPizzasIds();
        variables.pizzaIds = pizzaNft.getPizzasIds();
        PIZZANFT.Pizzas memory pizzaDetails;
        variables.lowestRarity = 100;
        variables.lowestRarityId = 0;
        variables.rarityTotal = 0;
        // uint256 pizzaId;
        // address pizzaOwner;
        // uint256 ingId;
        // uint256[] memory meats;
        // uint256[] memory toppings;
        variables.ingAvailable = false;
        variables.totalIngredientsNow = 3;
        for(uint256 i = 0; i < variables.totalPizzas; i++) {
            variables.pizzaId = variables.pizzaIds[i];
            pizzaDetails = pizzaNft.getPizzaDetails(variables.pizzaId);
            if(!pizzaDetails.unbaked) {
                if(pizzaDetails.base > 0) {
                    variables.ingId = userIngToIngIds[pizzaDetails.base];
                    variables.rarityTotal = variables.rarityTotal+ ingredientRarityPercent[variables.ingId];
                }
                if(pizzaDetails.sauce > 0) {
                    variables.ingId = userIngToIngIds[pizzaDetails.sauce];
                    variables.rarityTotal = variables.rarityTotal + ingredientRarityPercent[variables.ingId];
                }
                else {
                    variables.rarityTotal = variables.rarityTotal + ingredientRarityPercent[5000];
                }
                if(pizzaDetails.cheese > 0) {
                    variables.ingId = userIngToIngIds[pizzaDetails.cheese];
                    variables.rarityTotal = variables.rarityTotal + ingredientRarityPercent[variables.ingId];
                }
                else {
                    variables.rarityTotal = variables.rarityTotal + ingredientRarityPercent[5001];
                }
                for(uint256 x = 0; x < meatIngredients.length; x++) {
                    variables.totalIngredientsNow++;
                    variables.ingAvailable = false;
                    variables.meats = pizzaDetails.meats;
                    for(uint256 y=0; y < variables.meats.length; y++) {
                        variables.ingId = userIngToIngIds[variables.meats[y]];
                        if(variables.ingId == meatIngredients[x]) {
                            variables.ingAvailable = true;
                        }
                    }
                    if(variables.ingAvailable) {
                        variables.rarityTotal = variables.rarityTotal + ingredientRarityPercent[meatIngredients[x]];
                    }
                    else {
                        variables.rarityTotal = variables.rarityTotal + hundered.sub(ingredientRarityPercent[meatIngredients[x]]); 
                    }
                }
                for(uint256 x = 0; x < toppingIngredients.length; x++) {
                    variables.totalIngredientsNow++;
                    variables.ingAvailable = false;
                    variables.toppings = pizzaDetails.toppings;
                    for(uint256 y=0; y < variables.toppings.length; y++) {
                        variables.ingId = userIngToIngIds[variables.toppings[y]];
                        if(variables.ingId == toppingIngredients[x]) {
                            variables.ingAvailable = true;
                        }
                    }
                    if(variables.ingAvailable) {
                        variables.rarityTotal = variables.rarityTotal + ingredientRarityPercent[toppingIngredients[x]];
                    }
                    else {
                        variables.rarityTotal = variables.rarityTotal + hundered.sub(ingredientRarityPercent[toppingIngredients[x]]); 
                    }
                }
                variables.rarityTotal = variables.rarityTotal.div(variables.totalIngredientsNow);
                if(variables.rarityTotal < variables.lowestRarity) {
                    variables.lowestRarity = variables.rarityTotal;
                    variables.lowestRarityId = variables.pizzaId;
                    variables.pizzaOwner = pizzaDetails.from;
                }
                pizzaDetails.calculated = true;
                // pizzaDetails.rarity;

                // update the pizza list of pizzaNft
                pizzaNft.updatePizzaList(variables.pizzaId, pizzaDetails.from, pizzaDetails._pizzaId, pizzaDetails.base, pizzaDetails.sauce, pizzaDetails.cheese, pizzaDetails.meats, pizzaDetails.toppings, pizzaDetails.isRandom, pizzaDetails.unbaked, pizzaDetails.calculated, pizzaDetails.rarity);
                // pizzasList[pizzaId] = pizzaDetails; before
            }
        }
        if(variables.pizzaOwner != address(0)) {
            
            uint256 totalContractBalance = address(this).balance;
            uint256 availableContractBalance = totalContractBalance.sub(totalClaimable);
            uint256 rarityRewardShare = availableContractBalance.mul(RARITY_REWARD_SHARE).div(hundered);

            totalClaimable+=rarityRewardShare;
            RarityReward memory rarityReward = RarityReward(
                variables.pizzaOwner,
                false,
                rarityRewardShare,
                rarityRewardShare,
                variables.lowestRarityId,
                variables.lowestRarity
            );
            rarityRewardsList[totalRarityRewards] = rarityReward;
            rarityRewardsIds[totalRarityRewards] = variables.lowestRarityId;
            uint256[] storage userRareNfts = rarityRewardOwnerIds[variables.pizzaOwner];
            userRareNfts.push(totalRarityRewards);
            rarityRewardOwnerIds[variables.pizzaOwner] = userRareNfts;
            totalRarityRewards+=1;
            
            //for developer wallet
            uint256 currentClaimable = claimableList[developerFundWallet];
            currentClaimable += rarityRewardShare;
            claimableList[developerFundWallet] = currentClaimable;
            totalClaimable += currentClaimable;

            //for creator wallet
            currentClaimable = claimableList[owner()];
            currentClaimable += rarityRewardShare;
            claimableList[owner()] = currentClaimable;
            totalClaimable += currentClaimable;
        }
    }

    // rariry reward calculation
    function rarityRewardsCalculation() public {
        uint256 totalPizzas = pizzaNft.getTotalPizzas();
        bool newPizzas = pizzaNft.getNewPizzas();
    
        if(newPizzas && totalPizzas > 0) {
            traitRarity();
            calculateRarity();

            // set the newPizzas of pizzaNFT
            pizzaNft.setNewPizzas(false);
            // newPizzas = false;
        }
    }

    // update the developer fund wallet
    function updateDelevoperFundWallet(address wallet) public onlyOwner {
        developerFundWallet = wallet;
    }

    // check mints by ingredient id
    function checkMints(uint256 ingredientId) public view returns (IngredientCountResponse memory) {
        uint256 mintCount = ingredientMintCount[ingredientId];
        uint256 totalCount = ingredientTotalCount[ingredientId];
        IngredientCountResponse memory ingredientCount = IngredientCountResponse(
            totalCount,
            mintCount
        );
        return ingredientCount;
    }

    // get ingredients rarity
    function getIngredientRarity(uint256 ingredientId) public view returns (IngredientResponse memory) {
        uint256 rarity = ingredientRarityPercent[ingredientId];
        uint256 usedIn =  ingredientUsedCount[ingredientId];
        Ingredients memory ingredientDetails = ingredientsList[ingredientId];
        IngredientResponse memory ingredientResponse = IngredientResponse(
            ingredientDetails.name,
            rarity,
            usedIn
        );
        return (ingredientResponse);
    }

    // check claim reward
    function checkclaimableReward(address userAddress) public view returns(uint256) {
        uint256 claimableAmount = claimableList[userAddress];
        uint256 nftId = 0;
        uint256[] memory userRareNfts = rarityRewardOwnerIds[userAddress];
        for(uint256 x = 0; x < userRareNfts.length; x++) {
            nftId = userRareNfts[x];
            RarityReward memory rarityReward = rarityRewardsList[nftId];
            if(rarityReward.rewardPrice > 0 && !rarityReward.claimed) {
                claimableAmount+=rarityReward.rewardPrice;
            }
        }
        return claimableAmount;
    }

    // claim reward
    function claimReward() public payable {
        uint256 claimableAmount = claimableList[msg.sender];
        uint256 nftId = 0;
        uint256[] memory userRareNfts = rarityRewardOwnerIds[msg.sender];
        for(uint256 x = 0; x < userRareNfts.length; x++) {
            nftId = userRareNfts[x];
            RarityReward memory rarityReward = rarityRewardsList[nftId];
            if(rarityReward.rewardPrice > 0 && !rarityReward.claimed) {
                claimableAmount+=rarityReward.rewardPrice;
            }
        }
        require( claimableAmount > 0, "4");
        payable(msg.sender).transfer(claimableAmount);
        for(uint256 x = 0; x < userRareNfts.length; x++) {
            nftId = userRareNfts[x];
            RarityReward memory rarityReward = rarityRewardsList[nftId];
            rarityReward.rewardPrice = 0;
            rarityReward.claimed = true;
            rarityRewardsList[nftId] = rarityReward;
        }
        claimableList[msg.sender] = 0;
        totalClaimable -= claimableAmount;
    }

    // 1- create Ingredient (Admin)
    function createIngredient( string memory ingredientTokenURI, uint256 price, address artist, uint256 ingType, uint256 totalCount, string memory name) public {
        _IngredientIds.increment();
        uint256 _ingredientId = _IngredientIds.current();
        Ingredients memory ingredientDetail = Ingredients(
            name,
            _ingredientId,
            ingredientTokenURI,
            price,
            1,
            artist,
            ingType,
            totalCount
        );
        ingredientTotalCount[_ingredientId] = totalCount;
        ingredientsList[_ingredientId] = ingredientDetail;
        ingredientTypes[_ingredientId] = ingType;
        totalIngredients+=1;
        if(ingType == 4) {
            meatIngredients.push(_ingredientId);
        }
        if(ingType == 5) {
            toppingIngredients.push(_ingredientId);
        }
        _mint(msg.sender, _ingredientId, totalCount, "");
        emit createIngredientEvent(_ingredientId, ingredientTokenURI, price, artist, ingType);
    }

    // 2- user purchaseIngredients   
    function purchaseIngredients( uint256[] memory _ingredientIds) public payable {
        Ingredients memory ingredientDetail;
        uint256 totalPrice = 0;
        uint[] memory ingredientsAmount = new uint[](_ingredientIds.length);
        for(uint256 i = 0; i < _ingredientIds.length; i++) {
            ingredientDetail = ingredientsList[_ingredientIds[i]];
            require(ingredientDetail.created > 0, "55");
            ingredientsAmount[i] = 1;
            totalPrice+=ingredientDetail.price;
        }
        require(msg.value >= totalPrice, "in");
        uint[] memory mintedIds = new uint[](_ingredientIds.length);

        for(uint256 i = 0; i < _ingredientIds.length; i++) {
            ingredientDetail = ingredientsList[_ingredientIds[i]];
            address payable artist = payable(ingredientDetail.artist);
            uint256 currentMintCount = ingredientMintCount[_ingredientIds[i]];
            uint256 totalCount = ingredientTotalCount[_ingredientIds[i]];
            require(currentMintCount < totalCount, "5");
            _nftIds.increment();
            uint256 _nftId = _nftIds.current();

            // tranfering the token to the purchaser
            _safeBatchTransferFrom(owner(), msg.sender, _ingredientIds, ingredientsAmount, "0x00");

            // _setTokenURI(_nftId, ingredientDetail.metadata);
            if(artist != address(0)) {
                uint256 currentClaimable = claimableList[ingredientDetail.artist];
                currentClaimable += (ingredientDetail.price * ARTIST_SHARE / 100);
                claimableList[ingredientDetail.artist] = currentClaimable;
                totalClaimable += currentClaimable;
            }
            mintIngredientTypes[_nftId] = ingredientDetail.ingType;
            UserIngredients memory userIngredientDetails = UserIngredients(
                _ingredientIds[i],
                _nftId,
                msg.sender,
                false
            );
            userIngredientsList[_nftId] = userIngredientDetails;
            mintedIds[i] = _nftId;
            userIngToIngIds[_nftId] = ingredientDetail._ingredientId;
            ingredientMintCount[_ingredientIds[i]] = currentMintCount + 1;
        }
        
        emit mintIngredients(mintedIds);
    }

    // 3- buy and bake pizza and mint
    function buyAndBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public payable{

        uint256 baseR;
        uint256 sauceR;
        uint256 cheeseR;
        uint256[] memory meatsR;
        uint256[] memory toppingsR;
        uint256 userIngId = 0;
        if(base > 0) {
            userIngId = createUserIngredient(base);
            baseR = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(sauce > 0) {
            userIngId = createUserIngredient(sauce);
            sauceR = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(cheese > 0) {
            userIngId = createUserIngredient(cheese);
            cheeseR = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        uint256[] memory metasIngs = new uint256[](meats.length);
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                userIngId = createUserIngredient(meats[x]);
                increaseUsedCountByUserIngredient(userIngId);
                metasIngs[x] = userIngId;
            }
        }
        if(metasIngs.length > 0) {
            meatsR = metasIngs;
        }
        uint256[] memory topsIngs = new uint256[](toppings.length);
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                userIngId = createUserIngredient(toppings[x]);
                increaseUsedCountByUserIngredient(userIngId);
                topsIngs[x] = userIngId;
            }
        }
        if(topsIngs.length > 0) {
            toppingsR = topsIngs;
        }
        pizzaNft.buyAndBakePizzaAndMint(metadata, baseR, sauceR, cheeseR, meatsR, toppingsR);
        traitRarity();
    }

    // 4- random bake pizza and mint
    function randomBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public payable pizzaTypeAvailableValidation(1){
      
      IngredientsInfo memory ingDetails;
        uint256 userIngId = 0;
        if(base > 0) {
            userIngId = createUserIngredient(base);
            ingDetails.baseR = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(sauce > 0) {
            userIngId = createUserIngredient(sauce);
            ingDetails.sauceR = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(cheese > 0) {
            userIngId = createUserIngredient(cheese);
            ingDetails.cheeseR = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        uint256[] memory metasIngs = new uint256[](meats.length);
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                userIngId = createUserIngredient(meats[x]);
                increaseUsedCountByUserIngredient(userIngId);
                metasIngs[x] = userIngId;
            }
        }
        if(metasIngs.length > 0) {
            ingDetails.meatsR = metasIngs;
        }
        uint256[] memory topsIngs = new uint256[](toppings.length);
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                userIngId = createUserIngredient(toppings[x]);
                increaseUsedCountByUserIngredient(userIngId);
                topsIngs[x] = userIngId;
            }
        }
        if(topsIngs.length > 0) {
            ingDetails.toppingsR = topsIngs;
        }
        pizzaNft.randomBakePizzaAndMint(metadata, ingDetails.baseR, ingDetails.sauceR, ingDetails.cheeseR, ingDetails.meatsR, ingDetails.toppingsR);
        traitRarity();
    }

    // 5- bake pizza and mint 
    function bakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings) public payable{
        if(base > 0) {
            increaseUsedCountByUserIngredient(base);
        }
        if(sauce > 0) {
            increaseUsedCountByUserIngredient(sauce);
        }
        if(cheese > 0) {
            increaseUsedCountByUserIngredient(cheese);
        }
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                increaseUsedCountByUserIngredient(meats[x]);
            }
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                increaseUsedCountByUserIngredient(toppings[x]);
            }
        }

        pizzaNft.bakePizzaAndMint(metadata, base, sauce, cheese, meats, toppings);
        traitRarity();
    }

    // 6- unbake pizza 
    function unbakePizza( uint256 _pizzaId, uint256[] memory ingredientIds) public payable {
        for(uint8 i=0; i<ingredientIds.length; i++) {
                // changeIngredientUsedStatus(ingredientIds[i], false);
                decreaseUsedCountByUserIngredient(ingredientIds[i]);
        }

        // calling unbake Pizza Nft function
        pizzaNft.unbakePizza(_pizzaId);
        traitRarity();
    }

    // 7- rebake pizza
    function rebakePizza( uint256 _pizzaId, string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings, uint256[] memory allOldIngs, uint256[] memory oldIngs ) public payable {
        for(uint256 a = 0; a < allOldIngs.length; a++) {
            // changeIngredientUsedStatus(allOldIngs[a], false);
            decreaseUsedCountByUserIngredient(allOldIngs[a]);
        }
        for(uint256 a = 0; a < oldIngs.length; a++) {
            burnIngredient(oldIngs[a]);
        }
        if(base > 0) {
            increaseUsedCountByUserIngredient(base);
        }
        if(sauce > 0) {
            increaseUsedCountByUserIngredient(sauce);
        }
        if(cheese > 0) {
            increaseUsedCountByUserIngredient(cheese);
        }
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                increaseUsedCountByUserIngredient(meats[x]);
            }
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                increaseUsedCountByUserIngredient(toppings[x]);
            }
        }
        
        // calling the rebake pizza function of pizza nft contract
        pizzaNft.rebakePizza(_pizzaId, metadata, base, sauce, cheese, meats, toppings);
        traitRarity();
    }

    // change the status of pizza functions availabaility
    function changePizzaAvailable(uint256 pizzaType, bool status) public { // only owner
        if(pizzaType == 1) {
            randomBakePizzaAvailable = status;
        }
        else if(pizzaType == 2) {
            bakePizzaAvailable = status;
        }
        else if(pizzaType == 3) {
            buyAndBakePizzaAvailable = status;
        }
        else if(pizzaType == 4) {
            unbakePizzaAvailable = status;
        }
        else if(pizzaType == 5) {
            rebakePizzaAvailable = status;
        }
    }

    /** internal functions */ 
    function createUserIngredient(uint256 _ingredientId) internal returns(uint256) {
        Ingredients memory ingredientDetail = ingredientsList[_ingredientId];
        address payable artist = payable(ingredientDetail.artist);
        _nftIds.increment();
        uint256 _nftId = _nftIds.current();

        uint256 currentMintCount = ingredientMintCount[_ingredientId];
        uint256 totalCount = ingredientTotalCount[_ingredientId];
        require(currentMintCount < totalCount, "sold");

        _safeTransferFrom(owner(), msg.sender, _ingredientId, 1, "0x00");
        if(artist != address(0)) {
            uint256 currentClaimable = claimableList[ingredientDetail.artist];
            currentClaimable += (ingredientDetail.price * ARTIST_SHARE / 100);
            claimableList[ingredientDetail.artist] = currentClaimable;
            totalClaimable += currentClaimable;
        }
        mintIngredientTypes[_nftId] = ingredientDetail.ingType;
        UserIngredients memory userIngredientDetails = UserIngredients(
            _ingredientId,
            _nftId,
            msg.sender,
            false
        );
        userIngredientsList[_nftId] = userIngredientDetails;
        userIngToIngIds[_nftId] = ingredientDetail._ingredientId;
        ingredientMintCount[_ingredientId] = currentMintCount + 1;
        return _nftId;
    }

    function increaseUsedCountByUserIngredient(uint256 ingredientId) internal {
        uint256 ing = userIngToIngIds[ingredientId];
        uint256 ingCountUsed = ingredientUsedCount[ing]+1;
        ingredientUsedCount[ing] = ingCountUsed;
    }

    function decreaseUsedCountByUserIngredient(uint256 ingredientId) internal {
        uint256 ing = userIngToIngIds[ingredientId];
        if(ingredientUsedCount[ing] > 0) {
            uint256 ingCountUsed = ingredientUsedCount[ing]-1;
            ingredientUsedCount[ing] = ingCountUsed;
        }
    }

    function burnIngredient( uint256 ingredientId) internal {
        uint256 originalIngId = userIngToIngIds[ingredientId];
        mintIngredientTypes[ingredientId] = 0;
        userIngToIngIds[ingredientId] = 0;
        uint256 currentMintCount = ingredientMintCount[originalIngId];
        ingredientMintCount[originalIngId] = currentMintCount - 1;
        userIngredientsList[ingredientId] = UserIngredients(
            0,
            0,
            address(0),
            false
        );
    }
}