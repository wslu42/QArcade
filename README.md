# QArcade
A table-top arcade machine for quantum game developers, including open-sourcing the entire tutorials from coding to arcade schematics.

# Contributors
- Elton @ 建國中學
- Vincent @ IBM Research
- Chris @ 成功高中
- asd taiwan @ 桃園
- FetainerTW @ 嘉義中學
- iR/Voi @ 交通大學
- Haley @ UEIS
- Leo, YuChao, Willy @ 精誠高中

# Introducing QArcade: A coding friendly platform for quantum game developers

 It is our privilege to explore the cutting-edge quantum computational space during the NISQ era with qiskit. Looking back into the history especially in the 1970’s, arcade game developers already started the machine-level programming and prepared themselves as the future coders even if the hardware was still limited. In the meanwhile, game-driven breakthrough for the classical hardware, such as the first 3D acceleration chip Super FX in Nintendo super-NES home console, also demonstrated the possibilities where new hardware could be inspired by the game developers.

In this project, we hope to contribute to quantum education by leveraging the experience of classical arcades in the 70’s. We would like to introduce you the QArcade, a coding friendly platform for quantum game developers. By building and open-sourcing documents for QArcade, we hope to assist educators with limited programming backround and to inspire the next generation quantum workforce.
 
# A short survey of current quantum game developement environment with Qiskit

  Several approaches are currently available for quantum game developers using Qiskit. One typical approach is writing the game code in python modules pygame and qiskit, and then convert the game into executables with modules such as pyinstaller. The drawback of this approach is the executable usually inherited massive unused libraries such as matplotlibs from qiskit, which makes the executables easily over few hundred MB and difficult to share the game online. 
  
  The second approach is writing the game body in conventional game development engine such as Unity or Gadget, and then provide quantum simulation results from qiskit through python module Flask. This approach requires experience in setting up interface between python and localhost, which post a serious challenge for most quantum game enthusiasts we encountered, including ourselves, with limited server setup experience. 
  
  A third approach is to develop a quantum game in the native coding environment with quantum simulator backend codes, micro-qiskit. This approach enables a simple yet concise style to learn quantum computing via coding and is in particular favorable for general educators such as high school teachers, since no heavy-lifting interfacing setups between python and external kernels are required.
  
  We believe that the root of a prospered game community is an efficicent experience exchange between the players and the developers. By introducing QArcade, we hope to lower the technical threshold for the creative quantum enthusiasts and provide the developers a shorter turn-around time to realize a quantum game, which stimulates the inspirations for future quantum workforce during the NISQ era.
  
# The deliverables

  We would like to use micro-qiskit in pico8 with a combination of raspberry pi as our platform, and the final deliverable will be a table-top arcade machine for quantum game developers, including open-sourcing the entire tutorials from coding to arcade schematics. We will be delivering four quantum games developed in six weeks, and we will build and assemble the arcade with the aid of a 3D printer in parallel.
  
 Four quantum games are currently planned, and we hope to demonstrate two of them in two weeks. A complete set of physical arcade machine and four to five quantum games will be delivered at the beginning of June, 2021.
  
 After successful demonstration of QArcade, we would like to invite local high school teachers and students to participate our pico 8 developemnt tutorial and also quantum game jams over the summer. We hope to encourage the K-12 quantum education through learning and programming quantum games.
  
# Collaborations WANTED!

  Currently we are collaborating with students and teachers coming from four Taiwan local high schools/colleges to train and learn programming quantum games. If you are interested please join us by sending an email to Vincent (wslu42@gmail.com)!
