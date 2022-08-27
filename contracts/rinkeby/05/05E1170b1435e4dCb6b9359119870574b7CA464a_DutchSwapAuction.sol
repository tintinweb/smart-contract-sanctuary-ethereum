pragma solidity ^0.6.9;

//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//::::::::::: @#::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::::::::: ##::::::::::: @#:::::::::::: #@j:::::::::::::::::::::::::
//::::: ########: ##:: ##:: DUTCh>: ihD%y: #@Whdqy:::::::::::::::::::::
//::: ###... ###: ##:: ##:: @B... @@7...t: [email protected] [email protected]:::::::::::::::::::
//::: ##::::: ##: ##:: ##:: @Q::: @Q.::::: [email protected]:: [email protected]:::::::::::::::::::
//:::: ##DuTCH##: [email protected]@@#:: hQQQh <[email protected]@Q: [email protected]:: [email protected]:::::::::::::::::::
//::::::.......: [email protected]:::....:::......::...:::...:::::::::::::::::::
//:::::::::::::: [email protected]? [email protected]! 'DW;:::::: KK. [email protected]: NNKNQBdt:::::::::
//:::::::::::::: 'zqRqj*. [email protected] [email protected]: QQ: [email protected] [email protected] [email protected]@: @@U... @Q::::::::
//:::::::::::::::::...... [email protected]^ ^@@[email protected]@[email protected] <@Q^::: @@: @@}::: @@:::::::: 
//:::::::::::::::::: [email protected]@QKt... [email protected]@L.. [email protected] [email protected]: @@QQ#QQq:::::::::
//:::::::::::::::::::.....::::::...:::...::::.......: @@!.....:::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::::::::::::::::::::::::::::::::::::::: @@!::::::::::::::
//::::::::::::::01101100:01101111:01101111:01101011::::::::::::::::::::
//:::::01100100:01100101:01100101:01110000:01111001:01110010:::::::::::
//:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
//
// DutchSwap Auction V1.3.1
//   Copyright (c) 2020 DutchSwap.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  
// If not, see <https://github.com/deepyr/DutchSwap/>.
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// Authors:
// * Adrian Guerrera / Deepyr Pty Ltd
//
// ---------------------------------------------------------------------
// SPDX-License-Identifier: GPL-3.0-or-later                        
// ---------------------------------------------------------------------


import "./SafeMathPlus.sol";

contract DutchSwapAuction  {

    using SafeMathPlus for uint256;
    /// @dev The placeholder ETH address.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    uint256 public startDate;
    uint256 public endDate;
    uint256 public startPrice;
    uint256 public minimumPrice;
    uint256 public totalTokens;  // Amount to be sold
    uint256 public priceDrop; // Price reduction from startPrice at endDate
    uint256 public commitmentsTotal;
    uint256 public tokenWithdrawn;  // the amount of auction tokens already withdrawn
    bool private initialised;    
    bool public finalised;
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    address public auctionToken;
    address public paymentCurrency;
    address payable public wallet;  // Where the auction funds will get paid
    mapping(address => uint256) public commitments;
    mapping(address => uint256) public claimed;

    event AddedCommitment(address addr, uint256 commitment, uint256 price);


    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// @dev https://eips.ethereum.org/EIPS/eip-2200)
    modifier nonReentrant() {
        require(_status != _ENTERED);          // ReentrancyGuard: reentrant call
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /// @dev Init function
    function initDutchAuction(
        address _funder,
        address _token,
        uint256 _totalTokens,
        uint256 _startDate,
        uint256 _endDate,
        address _paymentCurrency,
        uint256 _startPrice,
        uint256 _minimumPrice,
        address payable _wallet
    )
        external
    {
        require(!initialised);                // Already Initialised
        require(_endDate > _startDate);       // End date earlier than start date
        require(_minimumPrice > 0);           // Minimum price must be greater than 0
        
        auctionToken = _token;
        paymentCurrency = _paymentCurrency;

        totalTokens = _totalTokens;
        startDate = _startDate;
        endDate = _endDate;
        startPrice = _startPrice;
        minimumPrice = _minimumPrice;
        wallet = _wallet;
        _status = _NOT_ENTERED;

        uint256 numerator = startPrice.sub(minimumPrice);
        uint256 denominator = endDate.sub(startDate);
        priceDrop = numerator.div(denominator);

        // There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
        _safeTransferFrom(auctionToken, _funder, _totalTokens);
        initialised = true;

    }

    // Dutch Auction Price Function
    // ============================
    //
    // Start Price -----
    //                   \
    //                    \
    //                     \
    //                      \ ------------ Clearing Price
    //                     / \            = AmountRaised/TokenSupply
    //      Token Price  --   \
    //                  /      \
    //                --        ----------- Minimum Price
    // Amount raised /          End Time
    //



    /// @notice The average price of each token from all commitments. 
    function tokenPrice() public view returns (uint256) {
        return commitmentsTotal.mul(1e18).div(totalTokens);
    }

      /// @notice Returns price during the auction 
    function priceFunction() public view returns (uint256) {
        /// @dev Return Auction Price
        if (block.timestamp <= startDate) {
            return startPrice;
        }
        if (block.timestamp >= endDate) {
            return minimumPrice;
        }
         return _currentPrice();
    }

    /// @notice The current clearing price of the Dutch auction
    function clearingPrice() public view returns (uint256) {
        /// @dev If auction successful, return tokenPrice
        if (tokenPrice() > priceFunction()) {
            return tokenPrice();
        }
        return priceFunction();
    }

    /// @notice How many tokens the user is able to claim
    function tokensClaimable(address _user) public view returns (uint256) {
        uint256 tokensAvailable = commitments[_user].mul(1e18).div(clearingPrice());
        return tokensAvailable.sub(claimed[msg.sender]);
    }

    /// @notice Total amount of tokens committed at current auction price–
    function totalTokensCommitted() public view returns(uint256) {
        return commitmentsTotal.mul(1e18).div(clearingPrice());
    }

    /// @notice Total amount of tokens remaining 
    function tokensRemaining() public view returns (uint256) {
        uint256 totalCommitted = totalTokensCommitted();
        if (totalCommitted >= totalTokens ) {
            return 0;
        } else {
            return totalTokens.sub(totalCommitted);
        }
    }

    /// @notice Returns price during the auction
    function _currentPrice() private view returns (uint256) {
        uint256 elapsed = block.timestamp.sub(startDate);
        uint256 priceDiff = elapsed.mul(priceDrop);
        return startPrice.sub(priceDiff);
    }

    //--------------------------------------------------------
    // Commit to buying tokens! 
    //--------------------------------------------------------

    /// @notice Buy Tokens by committing ETH to this contract address 
    /// @dev Needs extra gas limit for additional state changes
    receive () external payable {
        commitEthFrom(msg.sender);
    }

    /// @dev Needs extra gas limit for additional state changes
    function commitEth() public payable {
        commitEthFrom(msg.sender);
    }

    /// @notice Commit ETH to buy tokens for any address 
    function commitEthFrom (address payable _from) public payable {
        require(!finalised);                                  // Auction was cancelled
        require(address(paymentCurrency) == ETH_ADDRESS);       // Payment currency is not ETH
        // Get ETH able to be committed
        uint256 ethToTransfer = calculateCommitment( msg.value);

        // Accept ETH Payments
        uint256 ethToRefund = msg.value.sub(ethToTransfer);
        if (ethToTransfer > 0) {
            _addCommitment(_from, ethToTransfer);
        }
        // Return any ETH to be refunded
        if (ethToRefund > 0) {
            _from.transfer(ethToRefund);
        }
    }

    /// @notice Commit approved ERC20 tokens to buy tokens on sale
    function commitTokens(uint256 _amount) public {
        commitTokensFrom(msg.sender, _amount);
    }

    /// @dev Users must approve contract prior to committing tokens to auction
    function commitTokensFrom(address _from, uint256 _amount) public nonReentrant {
        require(!finalised);                                  // Auction was cancelled
        require(address(paymentCurrency) != ETH_ADDRESS);          // Only token transfers
        uint256 tokensToTransfer = calculateCommitment( _amount);
        if (tokensToTransfer > 0) {
            _safeTransferFrom(paymentCurrency, _from, tokensToTransfer);
            _addCommitment(_from, tokensToTransfer);
        }
    }

    /// @notice Returns the amout able to be committed during an auction
    function calculateCommitment( uint256 _commitment) 
        public view returns (uint256 committed) 
    {
        uint256 maxCommitment = totalTokens.mul(clearingPrice()).div(1e18);
        if (commitmentsTotal.add(_commitment) > maxCommitment) {
            return maxCommitment.sub(commitmentsTotal);
        }
        return _commitment;
    }

    /// @notice Commits to an amount during an auction
    function _addCommitment(address _addr,  uint256 _commitment) internal {
        require(block.timestamp >= startDate && block.timestamp <= endDate);  // Outside auction hours
        commitments[_addr] = commitments[_addr].add(_commitment);
        commitmentsTotal = commitmentsTotal.add(_commitment);
        emit AddedCommitment(_addr, _commitment, _currentPrice());

    }

    //--------------------------------------------------------
    // Finalise Auction
    //--------------------------------------------------------

    /// @notice Successful if tokens sold equals totalTokens
    function auctionSuccessful() public view returns (bool){
        return tokenPrice() >= clearingPrice();
    }

    /// @notice Returns bool if successful or time has ended
    /// @dev able to claim early if auction is successful
    function auctionEnded() public view returns (bool){
        return auctionSuccessful() || block.timestamp > endDate;
    }

    /// @notice Auction finishes successfully above the reserve
    /// @dev Transfer contract funds to initialised wallet. 
    function finaliseAuction () public nonReentrant {
        require(!finalised);                                  // Auction already finalised
        if( auctionSuccessful() ) 
        {
            /// @dev Successful auction
            /// @dev Transfer contributed tokens to wallet.
            _tokenPayment(paymentCurrency, wallet, commitmentsTotal);
        }
        else if ( commitmentsTotal == 0 && block.timestamp < startDate )
        {
            /// @dev Cancelled Auction
            /// @dev You can cancel the auction before it starts
            _tokenPayment(auctionToken, wallet, totalTokens);
        }
        else
        {
            /// @dev Failed auction
            /// @dev Return auction tokens back to wallet.
            require(block.timestamp > endDate, "Auction not finished yet" );    
            _tokenPayment(auctionToken, wallet, totalTokens);
        }
        finalised = true;
    }

    /// @notice Withdraw your tokens once the Auction has ended.
    function withdrawTokens() public nonReentrant {
        if( auctionSuccessful() ) 
        {
            /// @dev Successful auction! Transfer claimed tokens.
            uint256 tokensToClaim = tokensClaimable(msg.sender);
            require(tokensToClaim > 0, "No tokens to claim");      
            claimed[ msg.sender] = claimed[ msg.sender].add(tokensToClaim);
            tokenWithdrawn = tokenWithdrawn.add(tokensToClaim);
            _tokenPayment(auctionToken, msg.sender, tokensToClaim);
        }
        else 
        {
            /// @dev Auction did not meet reserve price.
            /// @dev Return committed funds back to user.
            require(block.timestamp > endDate);               // Auction not yet finished
            uint256 fundsCommitted = commitments[ msg.sender];
            require(fundsCommitted > 0);                      // No funds committed

            commitments[msg.sender] = 0;     // Stop multiple withdrawals and free some gas
            _tokenPayment(paymentCurrency, msg.sender, fundsCommitted);       
        }
    }

    //--------------------------------------------------------
    // Helper Functions
    //--------------------------------------------------------

    // There are many non-compliant ERC20 tokens... this can handle most, adapted from UniSwap V2
    // I'm trying to make it a habit to put external calls last (reentrancy)
    // You can put this in an internal function if you like.
    function _safeTransfer(address token, address to, uint256 amount) internal {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) = token.call(
            // 0xa9059cbb = bytes4(keccak256("transferFrom(address,address,uint256)"))
            abi.encodeWithSelector(0xa9059cbb, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 Transfer failed 
    }

    function _safeTransferFrom(address token, address from, uint256 amount) internal {
        // solium-disable-next-line security/no-low-level-calls
        (bool success, bytes memory data) = token.call(
            // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"))
            abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool)))); // ERC20 TransferFrom failed 
    }

    /// @dev Helper function to handle both ETH and ERC20 payments
    function _tokenPayment(address _token, address payable _to, uint256 _amount) internal {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }
}

pragma solidity ^0.6.9;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts
 */
library SafeMathPlus {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a <= b ? a : b;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}