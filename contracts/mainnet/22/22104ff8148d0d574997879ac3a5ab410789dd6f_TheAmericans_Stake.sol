/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
/**
 * @title TheAmericanStake
 * @author DevAmerican
 * @dev Used for Ethereum projects compatible with OpenSea
 */

pragma solidity ^0.8.4;

pragma solidity ^0.8.0;
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;
interface IERC721 is IERC165 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
}

pragma solidity ^0.8.0;
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

pragma solidity ^0.8.0;
library Address {
    
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.4;
interface ITheAmericansNFT {
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

pragma solidity ^0.8.4;
interface ITheAmericansToken {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

pragma solidity ^0.8.4;
contract TheAmericans_Stake is Ownable {
    uint256 public constant REWARD_RATE = 20;
    address public constant AMERICANS_ADDRESS = 0x4Ef3D9EaB34783995bc394d569845585aC805Ef8;
    address public constant AMERICANS_TOKEN = 0x993b8C5a26AC8a9abaBabbf10a0e3c4009b16D73;

    mapping(uint256 => uint256) internal americanTimeStaked;
    mapping(uint256 => address) internal americanStaker;
    mapping(address => uint256[]) internal stakerToAmericans;

    ITheAmericansNFT private constant _AmericanContract = ITheAmericansNFT(AMERICANS_ADDRESS);
    ITheAmericansToken private constant _AmericanToken = ITheAmericansToken(AMERICANS_TOKEN);

    bool public live = true;

    modifier stakingEnabled {
        require(live, "NOT_LIVE");
        _;
    }

    function getStakedAmericans(address staker) public view returns (uint256[] memory) {
        return stakerToAmericans[staker];
    }
    
    function getStakedAmount(address staker) public view returns (uint256) {
        return stakerToAmericans[staker].length;
    }

    function getStaker(uint256 tokenId) public view returns (address) {
        return americanStaker[tokenId];
    }

    function getAllRewards(address staker) public view returns (uint256) {
        uint256 totalRewards = 0;
        uint256[] memory americansTokens = stakerToAmericans[staker];
        for (uint256 i = 0; i < americansTokens.length; i++) {
            totalRewards += getReward(americansTokens[i]);
        }
        return totalRewards;
    }

    function stakeAmericanById(uint256[] calldata tokenIds) external stakingEnabled {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(_AmericanContract.ownerOf(id) == msg.sender, "NO_SWEEPING");
            _AmericanContract.transferFrom(msg.sender, address(this), id);
            stakerToAmericans[msg.sender].push(id);
            americanTimeStaked[id] = block.timestamp;
            americanStaker[id] = msg.sender;
        }
    }

    function unstakeAmericanByIds(uint256[] calldata tokenIds) external {
        uint256 totalRewards = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 id = tokenIds[i];
            require(americanStaker[id] == msg.sender, "NEEDS_TO_BE_OWNER");
            _AmericanContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getReward(id);
            removeTokenIdFromArray(stakerToAmericans[msg.sender], id);
            americanStaker[id] = address(0);
        }
        uint256 remaining = _AmericanToken.balanceOf(address(this));
        uint256 reward = totalRewards > remaining ? remaining : totalRewards;
        if(reward > 0){
            _AmericanToken.transfer(msg.sender, reward);
        }
    }

    function unstakeAll() external {
        require(getStakedAmount(msg.sender) > 0, "NONE_STAKED");
        uint256 totalRewards = 0;
        for (uint256 i = stakerToAmericans[msg.sender].length; i > 0; i--) {
            uint256 id = stakerToAmericans[msg.sender][i - 1];
            _AmericanContract.transferFrom(address(this), msg.sender, id);
            totalRewards += getReward(id);
            stakerToAmericans[msg.sender].pop();
            americanStaker[id] = address(0);
        }
        uint256 remaining = _AmericanToken.balanceOf(address(this));
        uint256 reward = totalRewards > remaining ? remaining : totalRewards;
        if(reward > 0){
            _AmericanToken.transfer(msg.sender, reward);
        }
    }

    function claimAll() external {
        uint256 totalRewards = 0;
        uint256[] memory americanTokens = stakerToAmericans[msg.sender];
        for (uint256 i = 0; i < americanTokens.length; i++) {
            uint256 id = americanTokens[i];
            totalRewards += getReward(id);
            americanTimeStaked[id] = block.timestamp;
        }
        uint256 remaining = _AmericanToken.balanceOf(address(this));
        _AmericanToken.transfer(msg.sender, totalRewards > remaining ? remaining : totalRewards);
    }

    function getReward(uint256 tokenId) internal view returns(uint256) {
        return (block.timestamp - americanTimeStaked[tokenId]) * REWARD_RATE / 86400 * 1 ether;
    }

    function removeTokenIdFromArray(uint256[] storage array, uint256 tokenId) internal {
        uint256 length = array.length;
        for (uint256 i = 0; i < length; i++) {
            if (array[i] == tokenId) {
                length--;
                if (i < length) {
                    array[i] = array[length];
                }
                array.pop();
                break;
            }
        }
    }

    function toggle() external onlyOwner {
        live = !live;
    }
}