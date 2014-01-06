experimental
============

Contains source code of experimental nature.


This customization needs to be done to the default node settings. They add required gems to the node and should be 
set before the dependencies cookbook is run on the node. It is set in the stack settings from OpsWorks console. 


{
    "dependencies": {
        "gems": {
            "eat": "0.1.8",
            "aws-sdk": "1.31.3"
        }
    }
}
