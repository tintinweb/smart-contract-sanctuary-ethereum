// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "Ownable.sol";
import "IERC721Receiver.sol";

// интерфейс для взаимодействия с контрактом медиа
interface Media {
    function changeFakeNewsURI(uint256 tokenId, string memory uri) external;
}

contract SuperDAO is Ownable, IERC721Receiver {
    // адрес контракта Voting
    address public addressVotingContract;
    // переменные для СМИ
    // переменная хранящая адрес смартконтракта медиа
    address public addressMediaContract;
    // карточка медиа
    struct mediaProfile {
        bool mediaAccreditation;
        int256 mediaRating;
        uint256 mediaBalance;
    }
    // словарь для хранения карточки медиа
    mapping(address => mediaProfile) public mediaArchive;
    // словарь по хранению информации о том, кто выпустил новость
    mapping(uint256 => address) public newsOwner;
    // минимальный стейк медиа
    uint256 public mediaDeposit = 0.5 ether;

    // переменные для ловцов фейков
    // карточка ловцов фейков
    struct fakeCatcherProfile {
        bool fakeCatcherAccreditation;
        int256 fakeCatcherRating;
        uint256 fakeCatcherBalance;
    }
    // словарь для хранения карточки ловцов фейков
    mapping(address => fakeCatcherProfile) public fakeCatchersArchive;
    // минимальный стейк ловцов
    uint256 public fakeCatchersDeposit = 0.5 ether;

    // ФУНКЦИИ, СВЯЗАННЫЕ С СМИ
    // Стейк медиа => подтверждение аккредитации
    function mediaStake() public payable {
        require(msg.value >= mediaDeposit);
        mediaProfile storage newMediaProfile = mediaArchive[msg.sender];
        newMediaProfile.mediaAccreditation = true;
        newMediaProfile.mediaRating = 100;
        newMediaProfile.mediaBalance = msg.value;
    }

    // Подтверждение аккредитации медиа для внешнего контракта
    function getMediaInfo(address _from)
        external
        view
        returns (
            bool,
            int256,
            uint256
        )
    {
        return (
            mediaArchive[_from].mediaAccreditation,
            mediaArchive[_from].mediaRating,
            mediaArchive[_from].mediaBalance
        );
    }

    // функция для изменения рейтинга медиа
    function changeRatingMedia(address _address, int256 delta) external {
        require(msg.sender == addressVotingContract);
        mediaArchive[_address].mediaRating += delta;
    }

    // Функция, которая вызывается из контракта Медиа для записи информации кто выпустил новость
    function setNewsOwner(address _mediaAddress, uint256 _tokenId) external {
        require(msg.sender == addressMediaContract);
        newsOwner[_tokenId] = _mediaAddress;
    }

    // функция, для вызова контрактами извне, чтобы узнать владельца новости
    function getNewsOwner(uint256 _tokenId) external view returns (address) {
        return newsOwner[_tokenId];
    }

    // устанавливаем адрес развернутого контракта медиа
    function setAddressMediaContract(address _addressMediaContract)
        external
        onlyOwner
    {
        addressMediaContract = _addressMediaContract;
    }

    // устанавливаем адрес развернутого контракта медиа
    function setAddressVotingContract(address _addressVotingContract)
        external
        onlyOwner
    {
        addressVotingContract = _addressVotingContract;
    }

    // функция, чтобы контракт смог принимать токены nft (новости)
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    // ФУНКЦИИ, СВЯЗАННЫЕ С ЛОВЦАМИ ФЕЙКОВ
    // Стейк ловцов => подтверждение аккредитации
    function fakeCatchersStake() public payable {
        require(msg.value >= fakeCatchersDeposit);
        fakeCatcherProfile storage newFakeCatcher = fakeCatchersArchive[
            msg.sender
        ];
        newFakeCatcher.fakeCatcherAccreditation = true;
        newFakeCatcher.fakeCatcherRating = 100;
        newFakeCatcher.fakeCatcherBalance = msg.value;
    }

    // Подтверждение аккредитации ловцов для внешнего контракта (открывающего голосования)
    function fakeCatchersInfo(address _from)
        external
        view
        returns (
            bool,
            int256,
            uint256
        )
    {
        return (
            fakeCatchersArchive[_from].fakeCatcherAccreditation,
            fakeCatchersArchive[_from].fakeCatcherRating,
            fakeCatchersArchive[_from].fakeCatcherBalance
        );
    }

    // функция для изменения рейтинга ловца
    function changeRatingFakeCatcher(address _address, int256 delta) external {
        require(msg.sender == addressVotingContract);
        fakeCatchersArchive[_address].fakeCatcherRating += delta;
    }

    // тестовая функция для замены токен URI
    function change(uint256 tokenId, string memory uri) public onlyOwner {
        Media(addressMediaContract).changeFakeNewsURI(tokenId, uri);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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