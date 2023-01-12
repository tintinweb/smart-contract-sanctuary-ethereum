pragma solidity >=0.8.12;

//              ／＞　 フ
//             | 　_　_| 
//           ／` ミ＿xノ    
//          /　　　　 |     made with 🤔 by nbaronia.eth
//         /　 ヽ　　 ﾉ     dedicated to the normies - if i can deploy, you can too 🫡
//         │　　|　|　| 
//     ／￣|　　 |　|　|
//      (￣ヽ＿_ヽ_)__)
//     ＼二)

contract UselessCat {

   
   event openMessage(string openStr);

   event closeMessage(string closeStr);

   // Declares a state variable `message` of type `string`.
   // State variables are variables whose values are permanently stored in contract storage. The keyword `public` makes variables accessible from outside a contract and creates a function that other contracts or clients can call to access the value.
   string public catName = "Neko";
   string public catSpeaks = "Meow";
   bool public boxIsOpen = false;



   // A public function that accepts a string argument and updates the `message` storage variable.
   function openTheBox() public {
      string memory openStr = string.concat("I opened the box said \"Oh great ",
                                            catName,
                                            " of the box, what is your wisdom?\" ");
      boxIsOpen = true;
      emit openMessage(openStr);

      closeTheBox();
   }

   function closeTheBox() private {
      string memory closeStr = string.concat(catName,
                                             " declared \" ",
                                             catSpeaks,
                                             " \", and closed the box.");
      boxIsOpen = false;

      emit closeMessage(closeStr);
   }


    // Pay to Change the name of the cat
    // Write in the wallet instead of I
    // create public state for namedBy
    // pay to change the dialogue
  

}