# es-test
Repository for SALS 

This repo will es launch an AWS VM running an Elasticsearch service secured with a unique username and password. 

** Dependencies **
- Use Mac / Linux for ease and confidence the script need not be customized for other machines. 
- You have installed pip. Else, follow https://pip.pypa.io//en/latest/installing/ (You will probably need root privs.)
- You have installed AWS CLI. Else, follow https://aws.amazon.com/cli/ (I suggest something like `sudo -H pip install awscli --upgrade --ignore-installed six` for Mac specifically.)
- You have properly configured AWS CLI using `aws configure` for your AWS account. 
- You have 0 EC2 instances prior to running this script. 
- You have only the default security group prior to running this script. 

** Instructions **
1) Follow and complete all of the DEPENDENCIES above.  
2) Run `init.sh`. 
3) Confirm the final output of the `init.sh` script is an echo that states `Elasticsearch installed, running, and secured with a non-default password.`. Above that, you should see the JSON response from a successfully queried Elasticsearch instance, using a non-default password. 

** Conversation Street **  
1) Brings up an AWS instance
2) Installs ElasticSearch configured in a way that requires credentials and provides encrypted communication
3) Demonstrates that it is functioning

I am confident I've completed #1 and #3. However, I've completed all of #3 except for the full encrypting. I've successfully encrypted the Elasticsearch instance and instructed it to run within SSL paramaters - but I've not succeeded in being able to securely communicate with it via HTTPS curls (using '--cacert').

I found it very enjoyable to complete this whole project with a single bash script. Of course, this could have been accomplished with Python, Ruby, Chef, AWS' solution - anything. What I enjoyed, however, was making something reasonably dynamic and configurable that felt 'stable'. Of course, dozens of scenarios could have caused problems. However, I ran the script dozens of times to come up with the requisite conditions I needed to test against to make the script fairly encapsulated and reusuable. Of course, YMMV.

In terms of resources I consulted in order to get the job done, I think the answer can be summed up with two domains: stackoverflow.com; aws.amazon.com. Of course, a few Bash references, AWS CLI third-party threads, and several old-school bulletins.

I thought this was a fun exercise. I finished at exactly four hours (bearing in mind I was multitasking during the first crack at it) with a script that got everything done except for an SSL conncection. I knew going in to it that the SSL aspect would be the biggest hurdle for me. I spent a decent amount of time on Saturday working on fixing up the SSL, til I determined I'd not made any progress. So I broke things apart and made it all more 'final' in the sense that I tested for conditions and made the script file itself more conditional/test-driven. I knew I'd need to do this, from the moment I started writing. After all that, I came back to the SSL problem. Amazingly, I got Elasticsearch up and running with SSL. Turns out I had some path/FQDN issues prior. It was great to see it running under HTTPS. Unfortunately, things were broken when trying to properly `curl` with `HTTPS`. I think with some more time googling which certificate I needed to use, and how, I could have gotten it up and running. But hey, let's discuss later. After a few more hours working on it on Saturday total, I put the project down. I cleaned up the SH file, and updated the zip late on Sunday, prior to commit and push to my repo. After that, I sent it back to your team. Enjoy!