/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract MerkleProof {
    // ETHER = 0x0000000000000000000000000000000000000000
    address public owner;
    address constant ETHER = address(0);
    uint256 public currentTimeStamp = block.timestamp;

    mapping(address => bool) public claims;
    mapping(string => uint256) public gameExpiryMap;

    constructor(address _owner) {
        owner = _owner;
    }

    event Claimed(address indexed token, address indexed to, uint256 value);

    event printLeaf(bytes32 leaf);

    function claim(
        address payable wallet,
        string memory gameId,
        uint256 amount,
        address token,
        bytes32[] memory proof,
        bytes32 root
    ) public {
        bytes32 _leaf = keccak256(abi.encode(wallet, amount, token));

        require(
            msg.sender == owner,
            "CPLMerkleDistributor: Claim function only callable by owner."
        );

        require(
            gameExpiryMap[gameId] != 0 &&
                gameExpiryMap[gameId] <= block.timestamp,
            "CPLMerkleDistributor: Claims for this game has ended."
        );

        require(
            isClaimable(root, _leaf, proof) && (claims[wallet] == false),
            "CPLMerkleDistributor: No claims available."
        );

        require(contractHasEnoughTokensForTransfer(token, amount)); //can be removed.

        _setClaimed(wallet);

        if (token == ETHER) {
            bool sent = wallet.send(amount);
            require(sent, "CPLMerkleDistributor: Transfer failed.");
        } else {
            require(
                IERC20(token).transfer(wallet, amount),
                "CPLMerkleDistributor: Transfer failed."
            );
        }

        emit Claimed(token, wallet, amount);
    }

    function _setClaimed(address wallet) private {
        claims[wallet] = true;
    }

    function getContractTokenBalance(address token)
        public
        view
        returns (uint256)
    {
        if (token == ETHER) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }

    function isClaimable(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof
    ) public pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(
                    abi.encode(computedHash, proofElement)
                );
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(
                    abi.encode(proofElement, computedHash)
                );
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }

    function withdrawTokensFromContract(
        address payable walletAddress,
        address token,
        uint256 amount
    ) public {
        require(msg.sender == owner);

        if (token == ETHER) {
            bool sent = walletAddress.send(amount);
            require(sent, "CPLMerkleDistributor: ETH withdraw failed.");
        } else {
            IERC20 _tokenInstance = IERC20(token);
            require(
                _tokenInstance.transfer(walletAddress, amount),
                "CPLMerkleDistributor: Token withdraw failed."
            );
        }
    }

    function contractHasEnoughTokensForTransfer(address token, uint256 amount)
        public
        view
        returns (bool)
    {
        if (token == ETHER) {
            if (amount >= address(this).balance) {
                return true;
            }
            return false;
        } else {
            if (amount >= IERC20(token).balanceOf(address(this))) {
                return true;
            }
            return false;
        }
    }

    function setClaim(address walletAddress, bool claimStatus) external {
        require(msg.sender == owner);
        claims[walletAddress] = claimStatus;
    }

    function setGameExpiry(string memory gameID, uint256 timestamp) external {
        require(msg.sender == owner);
        gameExpiryMap[gameID] = timestamp;
    }

    function sendEthToContract() public payable {}
}