// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "IERC20.sol";
import "Ownable.sol";

contract VotationContract is Ownable {
    uint256 public proposalTime = 0;
    uint256 public votationStartTime = 0;
    IERC20 public governanceToken;
    // Esta address corresponde al governanceToken en la red Rinkeby
    // Debe ser cambiado si se va a otra red, porque sino dara error.
    address public governanceTokenAddress =
        0x754E7753d5240366cFC785AC2fb8363633c45ddD;

    mapping(string => string) public publishedProposals_number;

    struct VotationResult {
        string proposalTitle;
        uint256 approvedVotes;
        uint256 refusedVotes;
        uint256 abstentionVotes;
    }
    VotationResult public votation_result =
        VotationResult("No proposal yet", 0, 0, 0);

    mapping(string => VotationResult) public proposalResults;

    address[] public voters;

    address[] public whiteList;

    enum Voting_state {
        Open,
        Closed,
        About_To_Start
    }
    Voting_state public state_voting = Voting_state.Closed;

    uint256 public votesCounter = 0;
    uint256 public proposalCounter = 0;
    uint256 public proposals_number;

    function changeTokenAddress(address newTokenAddress) public onlyOwner {
        governanceTokenAddress = newTokenAddress;
    }

    // Creacion de la propuesta con cada una de sus partes, pueden votar los que esten en la whitelist o los que tengan tokens

    function proposalCreation(
        string memory proposalTitle,
        string memory proposalDescription
    ) public {
        // Creamos la interfaz para interactuar con el contrato del token
        // La interfaz sera fijada con el deployment del contrato, por lo cual el contrato del token tendra que ya haber sido deployeado.

        governanceToken = IERC20(governanceTokenAddress);

        // Solo puede haber una propuesta a la vez gracias al state_voting y no puede haber una votacion en curso.

        require(
            state_voting == Voting_state.Closed,
            "Hay una votacion en curso"
        );

        proposals_number = proposalCounter;
        proposalCounter = proposalCounter + 1;

        if (
            governanceToken.balanceOf(msg.sender) > 0 &&
            governanceToken.balanceOf(msg.sender) >=
            (governanceToken.totalSupply() / 10)
        ) {
            // Publicar proposal
            publishedProposals_number[proposalTitle] = proposalDescription;

            // Cambio estado votacion - solo 1 propuesta a la vez
            state_voting = Voting_state.About_To_Start;

            // Nos aseguramos que la votacion empieza en cero
            votation_result = VotationResult(proposalTitle, 0, 0, 0);

            // Configurar el tiempo de delay entre la publicacion de la propuesta y el comienzo de la votacion
            proposalTime = block.timestamp;
            proposals_number = proposals_number + 1;
        } else {
            // Verificar que la cuenta que propone este en el whiteList
            bool whiteList_ok = false;
            for (uint256 i = 0; i < whiteList.length; i++) {
                if (msg.sender == whiteList[i]) {
                    whiteList_ok = true;
                }
            }

            if (whiteList_ok == true) {
                // Publicar proposal
                publishedProposals_number[proposalTitle] = proposalDescription;

                // Cambio estado votacion - solo 1 propuesta a la vez
                state_voting = Voting_state.About_To_Start;

                // Nos aseguramos que la votacion empieza en cero
                votation_result = VotationResult(proposalTitle, 0, 0, 0);

                //Configurar el tiempo de delay entre la publicacion de la propuesta y el comienzo de la votacion

                // Capaz se puede programar el tiempo a traves del script en python
                proposalTime = block.timestamp;
                proposals_number = proposals_number + 1;
            }
        }
        require(
            proposals_number == proposalCounter,
            "No proposal published, the user is not in whitelist or owner of enough tokens"
        );
    }

    function add_white_list(address whiteListNewAddress) public onlyOwner {
        whiteList.push(whiteListNewAddress);
    }

    function voting_start() public onlyOwner {
        // La votacion podra ser comenzada cuando se hace este call luego de un tiempo predefinido luego que la propuesta fue aceptada o de que se hace efectivamente una propuesta =
        require(
            proposalTime + 300 seconds < block.timestamp,
            "Is not yet time to vote"
        );
        require(state_voting == Voting_state.About_To_Start);

        state_voting = Voting_state.Open;
        votationStartTime = block.timestamp;
    }

    function approveProposal() public {
        require(state_voting == Voting_state.Open);

        bool whiteList_ok = false;
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (msg.sender == whiteList[i]) {
                whiteList_ok = true;
            }
        }
        require(
            governanceToken.balanceOf(msg.sender) >=
                (governanceToken.totalSupply() / 10) ||
                whiteList_ok == true
        );
        bool alreadyVoted = false;
        for (uint256 i = 0; i < voters.length; i++) {
            if (msg.sender == voters[i]) {
                alreadyVoted = true;
            }
        }
        require(alreadyVoted == false);

        votation_result.approvedVotes += 1;
        votesCounter += 1;
        voters.push(msg.sender);
    }

    function refuseProposal() public {
        require(state_voting == Voting_state.Open);

        bool whiteList_ok = false;
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (msg.sender == whiteList[i]) {
                whiteList_ok = true;
            }
        }
        require(
            governanceToken.balanceOf(msg.sender) >=
                (governanceToken.totalSupply() / 10) ||
                whiteList_ok == true
        );
        bool alreadyVoted = false;
        for (uint256 i = 0; i < voters.length; i++) {
            if (msg.sender == voters[i]) {
                alreadyVoted = true;
            }
        }
        require(alreadyVoted == false);

        votation_result.refusedVotes += 1;
        votesCounter += 1;
        voters.push(msg.sender);
    }

    function abstainProposal() public {
        require(state_voting == Voting_state.Open);

        bool whiteList_ok = false;
        for (uint256 i = 0; i < whiteList.length; i++) {
            if (msg.sender == whiteList[i]) {
                whiteList_ok = true;
            }
        }
        require(
            governanceToken.balanceOf(msg.sender) >=
                (governanceToken.totalSupply() / 10) ||
                whiteList_ok == true
        );
        bool alreadyVoted = false;
        for (uint256 i = 0; i < voters.length; i++) {
            if (msg.sender == voters[i]) {
                alreadyVoted = true;
            }
        }
        require(alreadyVoted == false);

        votation_result.abstentionVotes += 1;
        votesCounter += 1;
    }

    function closeVotation() public onlyOwner {
        require(
            votationStartTime + 300 seconds < block.timestamp,
            "Aun no ha transcurrido el tiempo necesario para concluir la votacion"
        );
        state_voting = Voting_state.Closed;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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