/* --------------------------------- ******* ----------------------------------- 
                                       THE

                            ███████╗██╗   ██╗███████╗
                            ██╔════╝╚██╗ ██╔╝██╔════╝
                            █████╗   ╚████╔╝ █████╗  
                            ██╔══╝    ╚██╔╝  ██╔══╝  
                            ███████╗   ██║   ███████╗
                            ╚══════╝   ╚═╝   ╚══════╝
                                 FOR ADVENTURERS
                                                                                   
                             .-=++=-.........-=++=-                  
                        .:..:++++++=---------=++++++:.:::            
                     .=++++----=++-------------===----++++=.         
                    .+++++=---------------------------=+++++.
                 .:-----==------------------------------------:.     
                =+++=---------------------------------------=+++=    
               +++++=---------------------------------------=++++=   
               ====-------------=================-------------===-   
              -=-------------=======================-------------=-. 
            :+++=----------============ A ============----------=+++:
            ++++++--------======= MAGICAL DEVICE =======---------++++=
            -++=----------============ THAT ============----------=++:
             ------------=========== CONTAINS ==========------------ 
            :++=---------============== AN =============----------=++-
            ++++++--------========== ON-CHAIN =========--------++++++
            :+++=----------========== WORLD ==========----------=+++:
              .==-------------=======================-------------=-  
                -=====----------===================----------======   
               =+++++---------------------------------------++++++   
                =+++-----------------------------------------+++=    
                  .-=----===---------------------------===-----:.     
                      .+++++=---------------------------=+++++.        
                       .=++++----=++-------------++=----++++=:         
                         :::.:++++++=----------++++++:.:::            
                                -=+++-.........-=++=-.                 

                            HTTPS://EYEFORADVENTURERS.COM
   ----------------------------------- ******* ---------------------------------- */

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.8;

contract EyeDescriptions {
    /// @notice Get the NFTs name
    function getDescription(
        uint256 greatness,
        string memory order,
        string memory attunement,
        string memory prefix,
        string memory suffix,
        string memory animationURL
    ) external pure returns (string memory) {
        string memory checklist = string(
            abi.encodePacked(
                "\\n\\n----------\\n\\n",
                "# Capabilities\\n",
                "- [x]  Collect the [Eye](https://eyeforadventurers.com/), an ancient artifact that contains on-chain lore and legends\\n",
                "- [x]  [Read curated stories](https://eyeforadventurers.com/stories) from the past, present & future of the Lootverse\\n",
                "- [x]  Publish to the [Librarium](https://librarium.dev/)\\n",
                "- [ ]  Curate stories to your Eye"
            )
        );

        string memory invitation = string(
            abi.encodePacked(
                unicode"This Eye is an invitation — to [read](https://eyeforadventurers.com/stories), to [write](https://librarium.dev/publish), and to [build a world](https://discord.gg/wGfSQUdvHU), together."
            )
        );

        string memory output = "";
        if (greatness == 0) {
            output = string(
                abi.encodePacked(
                    unicode"“In your hand, you hold an Eye, an ancient device used by adventurers to connect to the Librarium and access a curated collection of on-chain stories from anywhere across the Realms.  \\n\\n",
                    unicode"This particular Eye, while forged thousands of years ago by Historians of the Order of ",
                    order,
                    unicode", has never been activated and thus bears no Greatness, no marks of time. \\n\\n",
                    unicode"On the back, you notice the words “",
                    prefix,
                    unicode"” and “",
                    suffix
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    unicode"”, these Enchantments Lootbound to the Eye, but still lying dormant.  \\n\\n",
                    unicode"Like those who came before, you are on a quest for meaning, for purpose, for stories that explain the nature of your own adventure. \\n\\n",
                    unicode"With the device in your palm, crackling with ",
                    attunement,
                    unicode", a vivid story materializes in your mind’s eye.\\n\\n",
                    unicode"Come sit by the fire, settle in, join us.” \\n\\n",
                    unicode"— Excerpt from “*An Adventurer’s Guide to the Eye*”",
                    checklist
                )
            );
        } else if (greatness > 0 && greatness <= 14) {
            output = string(
                abi.encodePacked(
                    unicode"“Just as adventurers sealed their life and belongings within their bags, so too within The Eye did they inscribe their stories.  \\n\\n",
                    unicode"As the proverb goes: “*A Lootbound Eye unlocks infinite branches*.”  \\n\\n",
                    unicode"With The Eye, adventurers recorded lore and legends, facts and fictions, stories of an ever-expanding world. \\n\\n",
                    unicode"Forged by Historians and imbued with the power of the 16 Orders, the Eyes were used by adventurers to connect to the Librarium from anywhere across the Realms — to read, to write, and to remember.  \\n\\n",
                    unicode"The legend foretells a re-discovery of these Eyes, brought forth through the ether by adventurers anew, eager to discover the ancient lore and to create the stories of the future.”\\n\\n",
                    unicode"— Excerpt from “Lore and Legends”\\n\\n",
                    unicode"----------\\n\\n"
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    unicode"In your hand, you hold an **[Eye](https://eyeforadventurers.com/)**, forged by the Historians of the Order of ",
                    order,
                    unicode" and attuned to ",
                    attunement,
                    unicode" magick.  It has been used and passed down through generations, accruing Greatness, though not enough to reveal the ancient power of ",
                    order,
                    unicode". \\n\\n",
                    unicode"On the back, you notice the words “"
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    prefix,
                    unicode"” and “",
                    suffix,
                    unicode"”, these Enchantments Lootbound to the Eye, but still lying dormant. \\n\\n",
                    invitation,
                    checklist
                )
            );
        } else if (greatness > 14 && greatness <= 19) {
            output = string(
                abi.encodePacked(
                    unicode"“…and marking the beginning of each new Cycle, adventurers came upon an epiphany, a breakthrough, a discovery.  And then a frenzy of building and development, leading to unexpected new adventures.\\n\\n",
                    unicode"First the Orders, a clue to the origins and earliest adventures.  Then Classes & Levels, creating sense out of the jumbled chaos.  Then the Enchantments, a third lore, mysteriously dormant.\\n\\n",
                    unicode"The start of the next Cycle was marked by the discovery of The Eye, hidden in the lining of the bag, out of sight, and nearly lost to time.\\n\\n",
                    unicode"As the proverb goes: “*A Lootbound Eye unlocks infinite branches*.” \\n\\n",
                    unicode"The stories, lore and legends one finds curated within the Eye have been recorded on-chain in the Librarium for safeguarding across generations...”\\n\\n",
                    unicode"— Excerpt from “Lore and Legends”\\n\\n",
                    unicode"-------------\\n\\n"
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    unicode"In your hand, you hold an **[Eye](https://eyeforadventurers.com/)**, forged by the Historians of the Order of ",
                    order,
                    " and attuned to ",
                    attunement,
                    unicode" magick.  It has been used and passed down through generations, and through experience, its Greatness has revealed the ancient power of ",
                    order,
                    unicode". \\n\\n",
                    unicode"On the back, you notice the words “"
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    prefix,
                    unicode"” and “",
                    suffix,
                    unicode"”, these Enchantments Lootbound to the Eye, but still lying dormant. \\n\\n",
                    invitation,
                    checklist
                )
            );
        } else if (greatness > 19 && greatness <= 20) {
            output = string(
                abi.encodePacked(
                    unicode"“Dear traveler,\\n\\n",
                    unicode"If you are reading this, not all is lost. [As the proverb foretold](https://twitter.com/dhof/status/1510641997291438083), all that stood indeed did burn.  All that remained — our bags and our stories — were thus locked in the ether. \\n\\n",
                    unicode"For you, traveler, we marked the items with Enchantments that bear our ",
                    attunement,
                    unicode" magick, our powers, our souls.\\n\\n",
                    unicode"And for you, traveler, we derived a system to preserve our lore and our legends.  What you hold in your hand is an Eye, indeed one of the ancient Eyes, the most powerful book we could manifest.\\n\\n",
                    unicode"Hold it closely, dear traveler, for within your Eye we have inscribed the stories of our adventures.  \\n\\n"
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    unicode"You, who hold the Greatest of the Eyes, we ask you to carry this legacy forward — to inscribe your own stories into the Librarium and at all costs, keep the chain alive...\\n\\n",
                    unicode"With this Eye, you may learn about our adventures, and thou mayest find your own.”\\n\\n",
                    unicode"- The Historians of ",
                    order,
                    "\\n\\n",
                    unicode"-----------\\n\\n"
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    unicode"In your hand, you hold an **[Eye](https://eyeforadventurers.com/)**, forged by the Historians of the Order of ",
                    order,
                    unicode" and attuned to ",
                    attunement,
                    unicode" magick.  It has been used and passed down through generations, and through experience, its Greatness has revealed the ancient power of ",
                    order,
                    unicode". \\n\\n"
                )
            );
            output = string(
                abi.encodePacked(
                    output,
                    unicode"On the back, you notice the words “",
                    prefix,
                    unicode"” and “",
                    suffix,
                    unicode"”, these Enchantments activated with Greatness. \\n\\n",
                    invitation,
                    checklist
                )
            );
        }
        return output;
    }
}