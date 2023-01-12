pragma solidity >=0.8.12;

//              ／＞　 フ
//             | 　_　_| 
//           ／` ミ＿xノ    
//          /　　　　 |     
//         /　 ヽ　　 ﾉ
//         │　　|　|　|
//     ／￣|　　 |　|　|
//      (￣ヽ＿_ヽ_)__)
//     ＼二)

contract UselessCat {

   //Emitted when update function is called
   //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
   event openMessage(string openStr);

   event closeMessage(string closeStr);

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   string public catName = "Neko";
   bool public boxIsOpen = false;



   // A public function that accepts a string argument and updates the `message` storage variable.
   function openTheBox() public {
      string memory openStr = string.concat("I opened the box and awoke ", catName);
      boxIsOpen = true;
      emit openMessage(openStr);

      closeTheBox();
   }

   function closeTheBox() private {
      string memory closeStr = string.concat(catName, " closed the box and went back to sleep.");
      boxIsOpen = false;
      emit closeMessage(closeStr);
   }


  
}