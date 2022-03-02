/**
 *Submitted for verification at Etherscan.io on 2022-03-02
*/

contract IHateLife {
    Life public life;

    constructor(address life_) public {
        life = Life(life_);
    }

    function sendLove() public {
        life.receiveLove(true);
    }

    function sendHate() public {
        life.receiveLove(false);
        selfdestruct(payable(msg.sender));
    }
}

contract Life {
    bool public loved = true;

    function receiveLove(bool love) public {
        loved = love;
    }
}