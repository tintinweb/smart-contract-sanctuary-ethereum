pragma solidity ^0.4.0;

contract SpaCoin {
    int64 constant TOTAL_UNITS = 100000 ;
    int64 outstanding_coins ;
    address owner ;
    mapping (address => int64) holdings ;
    
    function SpaCoin() payable {
        outstanding_coins = TOTAL_UNITS ;
        owner = msg.sender ;
    }
    
    event CoinAllocation(address holder, int64 number, int64 remaining) ;
    event CoinMovement(address from, address to, int64 v) ;
    event InvalidCoinUsage(string reason) ;

    function getOwner()  constant returns(address) {
        return owner ;
    }

    function allocate(address newHolder, int64 value)  payable {
        if (msg.sender != owner) {
            InvalidCoinUsage('Only owner can allocate coins') ;
            return ;
        }
        if (value < 0) {
            InvalidCoinUsage('Cannot allocate negative value') ;
            return ;
        }

        if (value <= outstanding_coins) {
            holdings[newHolder] += value ;
            outstanding_coins -= value ;
            CoinAllocation(newHolder, value, outstanding_coins) ;
        } else {
            InvalidCoinUsage('value to allocate larger than outstanding coins') ;
        }
    }
    
    function move(address destination, int64 value)  {
        address source = msg.sender ;
        if (value <= 0) {
            InvalidCoinUsage('Must move value greater than zero') ;
            return ;
        }
        if (holdings[source] >= value) {
            holdings[destination] += value ;
            holdings[source] -= value ;
            CoinMovement(source, destination, value) ;
        } else {
            InvalidCoinUsage('value to move larger than holdings') ;
        }
    }
    
    function myBalance() constant returns(int64) {
        return holdings[msg.sender] ;
    }
    
    function holderBalance(address holder) constant returns(int64) {
        if (msg.sender != owner) return ;
        return holdings[holder] ;
    }

    function outstandingValue() constant returns(int64) {
        if (msg.sender != owner) return ;
        return outstanding_coins ;
    }
    
}