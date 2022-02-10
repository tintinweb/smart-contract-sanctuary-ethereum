/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract ForTimer {

    address payable to;
    uint send1;
    uint send2;
    uint status=0;
    uint sum;
    
    function send(uint timer) public payable {
        if(status==0){
            //Время для отправки новых монет
            send1=block.timestamp+timer;
            send2=block.timestamp+timer*2;

            //Данные о отправке
            to=payable(msg.sender);
            sum=msg.value/2;

            //Текущий статус для дальнейшего выполнения
            status=1;
        }
    }

    function sender() public {
        if(status==1 && block.timestamp>send1){
            to.transfer(sum);
            status=2;
        }else if(status==2 && block.timestamp>send2){
            //Send money 2
            to.transfer(sum);
            status = 0;
        }

    }

    function toSend(uint i) public view  returns(uint){
        if(i==1){
            return send1-block.timestamp;
        }else if(i==2){
            return send2-block.timestamp;
        }else{
            return 0;
        }
    }
}