![summary](https://user-images.githubusercontent.com/29524895/116581996-e7cd5180-a8e2-11eb-9f8c-9eb2a2d01344.png)

![logo_QArcade_new_light](https://user-images.githubusercontent.com/29524895/116025019-8032b000-a61d-11eb-9128-deb792fcc031.png)

# QArcade

A table-top arcade machine for quantum game developers, including open-sourcing the entire tutorials from coding to arcade schematics.

## Proposal presentations
- [Pitching the idea](https://youtu.be/jsbgksutqb0)
- [Presentation slides](https://www2.slideshare.net/WenSenLu1/120425-euq-hack-qarcadeproposal)
- [The half-built arcade](https://youtu.be/MFyIC066VZI)
- [The full-built arcade](https://youtu.be/LawvnygNNcw)

## Contributors
- Elton @ 建國中學
- Vincent @ Rutgers University
- Yu-Chen Hung @ 成功高中 CGSH
- asd taiwan @ 桃園
- FetainerTW @ 嘉義中學
- iR/Voi @ 交通大學
- Haley @ UEIS (United Education International School)
- Leo, YuChao, Willy @ 精誠高中

## 量子街機
我們是一群台灣南北，地球東西的量子人，在學習量子資訊的路上偶然相遇，相濡以沫。有感於自身學習量子電路之困頓經驗，希望藉由開發量子遊戲，降低國內中小學在量子教育上的興趣門檻、技術門檻、乃至經費門檻。量子電腦中關鍵的兩個概念：疊加(superposition)與纏結(entanglement)，對古典程式設計來說是全新的元素，我們期望藉由量子模擬模組 micro-Qiskit 與 Raspberry pi 微處理器的結合，提供開源教學素材，讓中小學教師、同學、乃至創客們也能享受使用量子電腦帶來的編程樂趣，進而與我們一起學習量子電腦及量子硬體。
如果您有興趣，請與文森 Vincent 聯絡(wslu42@gmail.com)！

註：本計畫前半部以[學生量子電腦交流會(SQCS)](https://discord.gg/KjWMRewQB2)名義同步投稿至Qiskit Hackathon Europe

# Introducing QArcade: A coding friendly platform for quantum game developers

 It is our privilege to explore the cutting-edge quantum computational space during the NISQ era with qiskit. Looking back into the history especially in the 1970’s, arcade game developers already started the machine-level programming and prepared themselves as the future coders even if the hardware was still limited. In the meanwhile, game-driven breakthrough for the classical hardware, such as the first 3D acceleration chip Super FX in Nintendo super-NES home console, also demonstrated the possibilities where new hardware could be inspired by the game developers.

In this project, we hope to contribute to quantum education by leveraging the experience of classical arcades in the 70’s. We would like to introduce you the QArcade, a coding friendly platform for quantum game developers. By building and open-sourcing documents for QArcade, we hope to assist educators with limited programming backround and to inspire the next generation quantum workforce.

## A short survey of current quantum game developement environment with Qiskit

  Several approaches are currently available for quantum game developers using Qiskit. One typical approach is writing the game code in python modules pygame and qiskit, and then convert the game into executables with modules such as pyinstaller. The drawback of this approach is the executable usually inherited massive unused libraries such as matplotlibs from qiskit, which makes the executables easily over few hundred MB and difficult to share the game online. 
  
  The second approach is writing the game body in conventional game development engine such as Unity or Gadget, and then provide quantum simulation results from qiskit through python module Flask. This approach requires experience in setting up interface between python and localhost, which post a serious challenge for most quantum game enthusiasts we encountered, including ourselves, with limited server setup experience. 
  
  A third approach is to develop a quantum game in the native coding environment with quantum simulator backend codes, micro-qiskit. This approach enables a simple yet concise style to learn quantum computing via coding and is in particular favorable for general educators such as high school teachers, since no heavy-lifting interfacing setups between python and external kernels are required.
  
  We believe that the root of a prospered game community is a real-time idea exchange between the players and the developers. By introducing QArcade, we hope to lower the technical threshold for the creative quantum enthusiasts and provide the developers a shorter turn-around time to realize a quantum game, which stimulates and inspires future quantum workforce during the NISQ era.

## Our motivation

  The motivation of this project is to help quantum enthusiastic building a classical machine hosting quantum development environment. It could be game development platform such as PICO-8 with micro-qiskit or full-fledged Python3 environment with Thonny which allows developers to access the full power of qiskit. 
  
  Indeed, for mature users such as graduate student with physics or computer science background it is perhaps more straightforward for them to use qiskit on their laptops for some serious quantum simulations, while this project is aiming at K-12 students and educators who has rather limited experience regarding quantum physics and/or programming. For these audiences PICO-8 and micro-qiskit offer a simple yet concise platform for the to concentrate on their creativity to navigate the quantum ideas such as superposition and entanglement.  

## The deliverables

  We would like to use micro-qiskit in pico8 with a combination of raspberry pi as our platform, and the final deliverable will be a table-top arcade machine for quantum game developers, including open-sourcing the entire tutorials from coding to arcade schematics. We will be delivering four quantum games developed in six weeks, and we will build and assemble the arcade with the aid of a 3D printer in parallel.
  
 Four quantum games are currently planned, and we hope to demonstrate two of them in two weeks. A complete set of physical arcade machine and four to five quantum games will be delivered at the beginning of June, 2021.
  
 After successful demonstration of QArcade, we would like to invite local high school teachers and students to participate our PICO-8 developemnt tutorial and also quantum game jams over the summer. We hope to encourage the K-12 quantum education through learning and programming quantum games.

# Collaborations WANTED!
  Currently we are collaborating with students and teachers coming from four Taiwan local high schools/colleges to train and learn programming quantum games. If you are interested please join us by sending an email to Vincent (wslu42@gmail.com)!
