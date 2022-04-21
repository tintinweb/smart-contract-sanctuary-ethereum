// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

//Interface
abstract contract ERC20Interface {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function transfer(address recipient, uint256 amount) public virtual;
}

abstract contract ERC721Interface {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual;

    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);
}

abstract contract ERC1155Interface {
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual;
}

abstract contract CustomInterface {
    function bridgeSafeTransferFrom(
        address dapp,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual;
}

contract BatchSwap is Ownable, Pausable, IERC721Receiver, IERC1155Receiver {
    address public TRADESQUAD; // is used to list users that pay no fees (give them vip nfts)
    address payable public VAULT; // to pay fees

    mapping(address => address) dappRelations; // to specify contracts for custom interfaced smart contracts

    mapping(address => bool) whiteList; // WhiteList to add dapp supported

    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 constant secs = 86400;

    Counters.Counter private _swapIds;

    // Flag for the createSwap
    bool private swapFlag;

    // Swap Struct
    struct swapStruct {
        address dapp; // dapp asset contract address, needs to be white-listed
        assetType typeStd; // the type? (TODO maybe change to enum)
        uint256[] tokenId; // list of asset ids (only 0 used i ncase of non-erc1155)
        uint256[] blc; //
        bytes data;
    }

    // Swap Status
    enum swapStatus {
        Opened,
        Closed,
        Cancelled
    }
    enum assetType {
        ERC20,
        ERC721,
        ERC1155
    }

    // SwapIntent Struct
    struct swapIntent {
        uint256 id;
        address payable addressOne; 
        uint256 valueOne; // must 
        address payable addressTwo; // must
        uint256 valueTwo; //  must
        uint256 swapStart;
        uint256 swapEnd;
        uint256 swapFee;
        swapStatus status;
    }

    // NFT Mapping
    mapping(uint256 => swapStruct[]) nftsOne; // assets to trade for initiators
    mapping(uint256 => swapStruct[]) nftsTwo; // assets to trade for confirtmators

    // Struct Payment
    struct paymentStruct {
        bool status;
        uint256 value;
    }

    // Mapping key/value for get the swap infos
    mapping(address => swapIntent[]) swapList; // storing swaps of each user
    mapping(uint256 => uint256) swapMatch; // to check swap_id => number in order of the user's swaps

    // Struct for the payment rules
    paymentStruct payment;

    // Events
    event swapEvent(
        address indexed _creator,
        uint256 indexed time,
        swapStatus indexed _status,
        uint256 _swapId,
        address _swapCounterPart
    );
    event paymentReceived(address indexed _payer, uint256 _value);

    constructor(address _TRADESQUAD, address _VAULT) {
        TRADESQUAD = _TRADESQUAD;
        VAULT = payable(_VAULT);
    }

    receive() external payable {
        emit paymentReceived(msg.sender, msg.value);
    }

    // Create Swap
    function createSwapIntent(
        swapIntent memory _swapIntent,
        swapStruct[] memory _nftsOne,
        swapStruct[] memory _nftsTwo
    ) public payable whenNotPaused {
        if (payment.status) {
            if (ERC721Interface(TRADESQUAD).balanceOf(msg.sender) == 0) {
                require(
                    msg.value >= payment.value.add(_swapIntent.valueOne),
                    "Not enought WEI for handle the transaction"
                );
                _swapIntent.swapFee = getWeiPayValueAmount();
            } else {
                require(
                    msg.value >= _swapIntent.valueOne,
                    "Not enought WEI for handle the transaction"
                );
                _swapIntent.swapFee = 0;
            }
        } else
            require(
                msg.value >= _swapIntent.valueOne,
                "Not enought WEI for handle the transaction"
            ); // check the pay,ent satisfies

        _swapIntent.addressOne = payable(msg.sender); // to ensure that only sender can create swap intents
        _swapIntent.id = _swapIds.current(); // set swap id
        _swapIntent.swapStart = block.timestamp; // set the time when swap started
        _swapIntent.swapEnd = 0; // will be set to non-zero on close/cancel
        _swapIntent.status = swapStatus.Opened; // identify the status of the swap

        swapMatch[_swapIds.current()] = swapList[msg.sender].length; // specify the number of the swap in the list of user swaps
        swapList[msg.sender].push(_swapIntent); // add the swpa intent to the user

        uint256 i;
        for (i = 0; i < _nftsOne.length; i++)
            nftsOne[_swapIntent.id].push(_nftsOne[i]); // fill swap with initalizer nfts

        for (i = 0; i < _nftsTwo.length; i++)
            nftsTwo[_swapIntent.id].push(_nftsTwo[i]); // fill swap with respondent nfts

        for (i = 0; i < nftsOne[_swapIntent.id].length; i++) {
            require(
                whiteList[nftsOne[_swapIntent.id][i].dapp],
                "A DAPP is not handled by the system"
            ); // check if Dapp is supported
            if (nftsOne[_swapIntent.id][i].typeStd == assetType.ERC20) {
                ERC20Interface(nftsOne[_swapIntent.id][i].dapp).transferFrom(
                    _swapIntent.addressOne,
                    address(this),
                    nftsOne[_swapIntent.id][i].blc[0]
                );
            } else if (nftsOne[_swapIntent.id][i].typeStd == assetType.ERC721) {
                ERC721Interface(nftsOne[_swapIntent.id][i].dapp)
                    .safeTransferFrom(
                        _swapIntent.addressOne,
                        address(this),
                        nftsOne[_swapIntent.id][i].tokenId[0],
                        nftsOne[_swapIntent.id][i].data
                    );
            } else if (
                nftsOne[_swapIntent.id][i].typeStd == assetType.ERC1155
            ) {
                ERC1155Interface(nftsOne[_swapIntent.id][i].dapp)
                    .safeBatchTransferFrom(
                        _swapIntent.addressOne,
                        address(this),
                        nftsOne[_swapIntent.id][i].tokenId,
                        nftsOne[_swapIntent.id][i].blc,
                        nftsOne[_swapIntent.id][i].data
                    );
            } else {
                CustomInterface(dappRelations[nftsOne[_swapIntent.id][i].dapp])
                    .bridgeSafeTransferFrom(
                        nftsOne[_swapIntent.id][i].dapp,
                        _swapIntent.addressOne,
                        dappRelations[nftsOne[_swapIntent.id][i].dapp],
                        nftsOne[_swapIntent.id][i].tokenId,
                        nftsOne[_swapIntent.id][i].blc,
                        nftsOne[_swapIntent.id][i].data
                    );
            }
        }

        emit swapEvent(
            msg.sender,
            (block.timestamp - (block.timestamp % secs)),
            _swapIntent.status,
            _swapIntent.id,
            _swapIntent.addressTwo
        );
        _swapIds.increment();
    }

    // Close the swap
    function closeSwapIntent(address _swapCreator, uint256 _swapId)
        public
        payable
        whenNotPaused
    {
        require(
            swapList[_swapCreator][swapMatch[_swapId]].status ==
                swapStatus.Opened,
            "Swap Status is not opened"
        );
        require(
            swapList[_swapCreator][swapMatch[_swapId]].addressTwo == msg.sender,
            "You're not the interested counterpart"
        );
        if (payment.status) {
            if (ERC721Interface(TRADESQUAD).balanceOf(msg.sender) == 0) {
                require(
                    msg.value >=
                        payment.value.add(
                            swapList[_swapCreator][swapMatch[_swapId]].valueTwo
                        ),
                    "Not enought WEI for handle the transaction"
                );
                // Move the fees to the vault
                if (
                    payment.value.add(
                        swapList[_swapCreator][swapMatch[_swapId]].swapFee
                    ) > 0
                )
                    VAULT.transfer(
                        payment.value.add(
                            swapList[_swapCreator][swapMatch[_swapId]].swapFee
                        )
                    );
            } else {
                require(
                    msg.value >=
                        swapList[_swapCreator][swapMatch[_swapId]].valueTwo,
                    "Not enought WEI for handle the transaction"
                );
                if (swapList[_swapCreator][swapMatch[_swapId]].swapFee > 0)
                    VAULT.transfer(
                        swapList[_swapCreator][swapMatch[_swapId]].swapFee
                    );
            }
        } else
            require(
                msg.value >=
                    swapList[_swapCreator][swapMatch[_swapId]].valueTwo,
                "Not enought WEI for handle the transaction"
            );

        swapList[_swapCreator][swapMatch[_swapId]].addressTwo = payable(
            msg.sender
        ); // to make address payable
        swapList[_swapCreator][swapMatch[_swapId]].swapEnd = block.timestamp; // set time of swap closing (TODO maybe move in the end)
        swapList[_swapCreator][swapMatch[_swapId]].status = swapStatus.Closed; // (TODO maybe move in the end)

        //From Owner 1 to Owner 2
        uint256 i;
        for (i = 0; i < nftsOne[_swapId].length; i++) {
            require(
                whiteList[nftsOne[_swapId][i].dapp],
                "A DAPP is not handled by the system"
            );
            if (nftsOne[_swapId][i].typeStd == assetType.ERC20) {
                ERC20Interface(nftsOne[_swapId][i].dapp).transfer(
                    swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                    nftsOne[_swapId][i].blc[0]
                );
            } else if (nftsOne[_swapId][i].typeStd == assetType.ERC721) {
                ERC721Interface(nftsOne[_swapId][i].dapp).safeTransferFrom(
                    address(this),
                    swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                    nftsOne[_swapId][i].tokenId[0],
                    nftsOne[_swapId][i].data
                );
            } else if (nftsOne[_swapId][i].typeStd == assetType.ERC1155) {
                ERC1155Interface(nftsOne[_swapId][i].dapp)
                    .safeBatchTransferFrom(
                        address(this),
                        swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                        nftsOne[_swapId][i].tokenId,
                        nftsOne[_swapId][i].blc,
                        nftsOne[_swapId][i].data
                    );
            } else {
                CustomInterface(dappRelations[nftsOne[_swapId][i].dapp])
                    .bridgeSafeTransferFrom(
                        nftsOne[_swapId][i].dapp,
                        dappRelations[nftsOne[_swapId][i].dapp],
                        swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                        nftsOne[_swapId][i].tokenId,
                        nftsOne[_swapId][i].blc,
                        nftsOne[_swapId][i].data
                    );
            }
        }
        if (swapList[_swapCreator][swapMatch[_swapId]].valueOne > 0)
            swapList[_swapCreator][swapMatch[_swapId]].addressTwo.transfer(
                swapList[_swapCreator][swapMatch[_swapId]].valueOne
            );

        //From Owner 2 to Owner 1
        for (i = 0; i < nftsTwo[_swapId].length; i++) {
            require(
                whiteList[nftsTwo[_swapId][i].dapp],
                "A DAPP is not handled by the system"
            );
            if (nftsTwo[_swapId][i].typeStd == assetType.ERC20) {
                ERC20Interface(nftsTwo[_swapId][i].dapp).transferFrom(
                    swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                    swapList[_swapCreator][swapMatch[_swapId]].addressOne,
                    nftsTwo[_swapId][i].blc[0]
                );
            } else if (nftsTwo[_swapId][i].typeStd == assetType.ERC721) {
                ERC721Interface(nftsTwo[_swapId][i].dapp).safeTransferFrom(
                    swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                    swapList[_swapCreator][swapMatch[_swapId]].addressOne,
                    nftsTwo[_swapId][i].tokenId[0],
                    nftsTwo[_swapId][i].data
                );
            } else if (nftsTwo[_swapId][i].typeStd == assetType.ERC1155) {
                ERC1155Interface(nftsTwo[_swapId][i].dapp)
                    .safeBatchTransferFrom(
                        swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                        swapList[_swapCreator][swapMatch[_swapId]].addressOne,
                        nftsTwo[_swapId][i].tokenId,
                        nftsTwo[_swapId][i].blc,
                        nftsTwo[_swapId][i].data
                    );
            } else {
                CustomInterface(dappRelations[nftsTwo[_swapId][i].dapp])
                    .bridgeSafeTransferFrom(
                        nftsTwo[_swapId][i].dapp,
                        swapList[_swapCreator][swapMatch[_swapId]].addressTwo,
                        swapList[_swapCreator][swapMatch[_swapId]].addressOne,
                        nftsTwo[_swapId][i].tokenId,
                        nftsTwo[_swapId][i].blc,
                        nftsTwo[_swapId][i].data
                    );
            }
        }
        if (swapList[_swapCreator][swapMatch[_swapId]].valueTwo > 0)
            swapList[_swapCreator][swapMatch[_swapId]].addressOne.transfer(
                swapList[_swapCreator][swapMatch[_swapId]].valueTwo
            );

        emit swapEvent(
            msg.sender,
            (block.timestamp - (block.timestamp % secs)),
            swapStatus.Closed,
            _swapId,
            _swapCreator
        );
    }

    // Cancel Swap
    function cancelSwapIntent(uint256 _swapId) public {
        require(
            swapList[msg.sender][swapMatch[_swapId]].addressOne == msg.sender,
            "You're not the interested counterpart"
        );
        require(
            swapList[msg.sender][swapMatch[_swapId]].status ==
                swapStatus.Opened,
            "Swap Status is not opened"
        );
        //Rollback
        if (swapList[msg.sender][swapMatch[_swapId]].swapFee > 0)
            payable(msg.sender).transfer(
                swapList[msg.sender][swapMatch[_swapId]].swapFee
            );
        uint256 i;
        for (i = 0; i < nftsOne[_swapId].length; i++) {
            if (nftsOne[_swapId][i].typeStd == assetType.ERC20) {
                ERC20Interface(nftsOne[_swapId][i].dapp).transfer(
                    swapList[msg.sender][swapMatch[_swapId]].addressOne,
                    nftsOne[_swapId][i].blc[0]
                );
            } else if (nftsOne[_swapId][i].typeStd == assetType.ERC721) {
                ERC721Interface(nftsOne[_swapId][i].dapp).safeTransferFrom(
                    address(this),
                    swapList[msg.sender][swapMatch[_swapId]].addressOne,
                    nftsOne[_swapId][i].tokenId[0],
                    nftsOne[_swapId][i].data
                );
            } else if (nftsOne[_swapId][i].typeStd == assetType.ERC1155) {
                ERC1155Interface(nftsOne[_swapId][i].dapp)
                    .safeBatchTransferFrom(
                        address(this),
                        swapList[msg.sender][swapMatch[_swapId]].addressOne,
                        nftsOne[_swapId][i].tokenId,
                        nftsOne[_swapId][i].blc,
                        nftsOne[_swapId][i].data
                    );
            } else {
                CustomInterface(dappRelations[nftsOne[_swapId][i].dapp])
                    .bridgeSafeTransferFrom(
                        nftsOne[_swapId][i].dapp,
                        dappRelations[nftsOne[_swapId][i].dapp],
                        swapList[msg.sender][swapMatch[_swapId]].addressOne,
                        nftsOne[_swapId][i].tokenId,
                        nftsOne[_swapId][i].blc,
                        nftsOne[_swapId][i].data
                    );
            }
        }

        if (swapList[msg.sender][swapMatch[_swapId]].valueOne > 0)
            swapList[msg.sender][swapMatch[_swapId]].addressOne.transfer(
                swapList[msg.sender][swapMatch[_swapId]].valueOne
            );

        swapList[msg.sender][swapMatch[_swapId]].swapEnd = block.timestamp;
        swapList[msg.sender][swapMatch[_swapId]].status = swapStatus.Cancelled;
        emit swapEvent(
            msg.sender,
            (block.timestamp - (block.timestamp % secs)),
            swapStatus.Cancelled,
            _swapId,
            address(0)
        );
    }

    // Set Trade Squad address
    function setTradeSquadAddress(address _tradeSquad) public onlyOwner {
        TRADESQUAD = _tradeSquad;
    }

    // Set Vault address
    function setVaultAddress(address payable _vault) public onlyOwner {
        VAULT = _vault;
    }

    // Handle dapp relations for the bridges
    function setDappRelation(address _dapp, address _CustomInterface)
        public
        onlyOwner
    {
        dappRelations[_dapp] = _CustomInterface;
    }

    // Handle the whitelist
    function setWhitelist(address _dapp, bool _status) public onlyOwner {
        whiteList[_dapp] = _status;
    }

    // Edit CounterPart Address
    function editCounterPart(uint256 _swapId, address payable _counterPart)
        public
    {
        require(
            msg.sender == swapList[msg.sender][swapMatch[_swapId]].addressOne,
            "Message sender must be the swap creator"
        );
        swapList[msg.sender][swapMatch[_swapId]].addressTwo = _counterPart;
    }

    // Set the payment
    function setPayment(bool _status, uint256 _value)
        public
        onlyOwner
        whenNotPaused
    {
        payment.status = _status;
        payment.value = _value * (1 wei);
    }

    // Get whitelist status of an address
    function getWhiteList(address _address) public view returns (bool) {
        return whiteList[_address];
    }

    // Get Trade fees
    function getWeiPayValueAmount() public view returns (uint256) {
        return payment.value;
    }

    // Get swap infos
    function getSwapListByAddress(address _creator)
        public
        view
        returns (swapIntent[] memory)
    {
        return swapList[_creator];
    }

    // Get swap infos
    function getSwapIntentByAddress(address _creator, uint256 _swapId)
        public
        view
        returns (swapIntent memory)
    {
        return swapList[_creator][swapMatch[_swapId]];
    }

    // Get swapStructLength
    function getSwapStructSize(uint256 _swapId, bool _nfts)
        public
        view
        returns (uint256)
    {
        if (_nfts) return nftsOne[_swapId].length;
        else return nftsTwo[_swapId].length;
    }

    // Get swapStruct
    function getSwapStruct(
        uint256 _swapId,
        bool _nfts,
        uint256 _index
    ) public view returns (swapStruct memory) {
        if (_nfts) return nftsOne[_swapId][_index];
        else return nftsTwo[_swapId][_index];
    }

    // Get swapStruct
    function getSwapStructs(
        uint256 _swapId,
        bool _nfts
    ) public view returns (swapStruct[] memory) {
        if (_nfts) return nftsOne[_swapId];
        else return nftsTwo[_swapId];
    }

    //Interface IERC721/IERC1155
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata id,
        uint256[] calldata value,
        bytes calldata data
    ) external override returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            );
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceID == 0x01ffc9a7 || interfaceID == 0x4e2312e0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}