# QArcade
A table-top arcade machine for quantum game developers, including open-sourcing the entire tutorials from coding to arcade schematics.

# Introducing QArcade: A coding friendly platform for quantum game developers

Looking back into the history especially 1970’s when computer hardware is still quite limited, arcade game developers already started the development of low-level programming and prepared of themselves as future coders. In the meanwhile, game-driven breakthrough on the hardware, such as the Super FX 3D acceleration chip Nintendo in super-NES home console, also demonstrated the possibilities where new hardware technologies could be inspired by the game developers.

  It is a privilege to explore the new quantum computational space during the NISQ era with qiskit. In this project, we hope to contribute to quantum education by leveraging the experience of classical arcades in the 70’s, the QArcade. By building a coding friendly platform for quantum game developers, we hope QArcade can assist education and inspire the next generation quantum workforce.
 
# A short survey of current quantum game developement environment

  Several approaches are currently available for quantum game developers. One typical approach is writing the game code in python modules pygame and qiskit, and then convert the game into executables with modules such as pyinstaller. The drawback of this approach is the executable usually inherited massive unused modules such as matplotlibs from qiskit, which makes the executables easily over few hundred MB and difficult to share the game online. 
  
  The second approach is writing the game body in professional game development engine such as Unity or Gadget, and then provide quantum simulation results from qiskit through python module Flask. This approach requires experience in setting up interface between python and localhost, which post a serious challenge for most quantum game enthusiasts we encountered, including ourselves, with limited Java or server setup experience. 
  
  A third approach is to develop a quantum game in the native coding environment with quantum simulator backend codes, micro-qiskit. This approach enables a simple yet concise style to learn quantum computing via coding and is in particular favorable for general educators such as high school teachers, since no heavy-lifting interfacing setups between python and external kernels are required.
  
# The deliverables

  We would like to use micro-qiskit in pico8 with a combination of raspberry pi as our platform, and the final deliverable will be a table-top arcade machine for quantum game developers, including open-sourcing the entire tutorials from coding to arcade schematics. We will be delivering four quantum games developed in six weeks, and we will build and assemble the arcade with the aid of a 3D printer in parallel.
  
 Four quantum games are currently planned and we hope to demonstrate two of them in two weeks. A complete set of physical arcade machine and four to five quantum games will be delivered at the begining of June, 2021.
  
  
