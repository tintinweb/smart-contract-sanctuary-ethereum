// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract blinkit {
    struct Blink {
        address owner;
        string tittle;
        string description;
        uint256 amountcollected;
        string image;
        address[] blinkers;
        uint256[] blinkamount;
    }
    mapping (uint256 => Blink) public blinks;

    uint256 public blinkcount = 0;

    function createBlink(
        address _owner,
        string memory _tittle,
        string memory _description,
        string memory _image

    ) public returns (uint256){
        Blink storage blink  = blinks[blinkcount];

        blink.owner = _owner;
        blink.tittle = _tittle;
        blink.description = _description;
        blink.amountcollected = 0;
        blink.image = _image;

        blinkcount++;

        return blinkcount-1;

    }

    function donateToBlink(uint256 _id ) public payable{

        uint256 amount = msg.value;
        Blink storage blink = blinks[_id];
        blink.blinkers.push(msg.sender);
        blink.blinkamount.push(amount);

        (bool sent, )= payable(blink.owner).call{value: amount}("");

        if(sent)
        {
            blink.amountcollected += amount;
        }

    }

    function getBlink( uint256 _id) view public returns(address[] memory , uint256[]memory ){
                return(
                    blinks[_id].blinkers,
                    blinks[_id].blinkamount);
            }

    function getBlinkers()public view returns(Blink[] memory ){

        Blink[] memory allblinkers = new Blink[](blinkcount);
        for(uint256 i = 0; i < blinkcount; i++){
            allblinkers[i] = blinks[i];
        }
        return allblinkers;
    }
}