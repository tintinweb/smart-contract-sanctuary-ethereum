/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: GPL-3.0

/*
      ::::::::   ::::::::  ::::    :::  ::::::::   ::::::::  :::        ::::::::::          ::::    ::: :::::::::: ::::::::::: 
    :+:    :+: :+:    :+: :+:+:   :+: :+:    :+: :+:    :+: :+:        :+:                 :+:+:   :+: :+:            :+:      
   +:+        +:+    +:+ :+:+:+  +:+ +:+        +:+    +:+ +:+        +:+                 :+:+:+  +:+ +:+            +:+       
  +#+        +#+    +:+ +#+ +:+ +#+ +#++:++#++ +#+    +:+ +#+        +#++:++#            +#+ +:+ +#+ :#::+::#       +#+        
 +#+        +#+    +#+ +#+  +#+#+#        +#+ +#+    +#+ +#+        +#+                 +#+  +#+#+# +#+            +#+         
#+#    #+# #+#    #+# #+#   #+#+# #+#    #+# #+#    #+# #+#        #+#                 #+#   #+#+# #+#            #+#          
########   ########  ###    ####  ########   ########  ########## ##########          ###    #### ###            ###           
*/

pragma solidity ^0.8.0;


contract HackerRiddlePart6_Final_Key {
	
        function finalKey(string memory key_1, string memory key_2, string memory key_3, string memory key_4) public pure returns (string memory) {

        string[5] memory json;

        json[0] = string(
			abi.encodePacked('/hacker_riddle_part_6_')
		);

        json[1] = string(
			abi.encodePacked(key_4, "-")
		);
        json[2] = string(
			abi.encodePacked(key_2, "-")
		);

        json[3] = string(
			abi.encodePacked(key_1, "-")
		);
        json[4] = string(
			abi.encodePacked(key_3)
		);

        string memory result = 
			string(
				abi.encodePacked(
					json[0],
					json[1],
					json[2],
					json[3],
					json[4]
				)
        );

        return string(abi.encodePacked(result));
    }

}