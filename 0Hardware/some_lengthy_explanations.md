I am trying to provide some reason of my several decisions when building the QArcade, in case anyone is interested in improving it he/she might found this useful.

# Why do we choose an arcade to be our platform

We have been asking ourselves lots of similar questions, and let me try to address each of them seperately in this section

1.	Why would you build an arcade while the entire game can be developed with PICO-8 on standard OS and laptop?
> Great question. It is certainly true that qiskit can be executed on an averaged laptop, but we are aiming at quantum educations for K-12 students who might not have budgets to own a laptop. Based on our current estimate, the overall cost of a quantum arcade can be controlled within $300 USD, which is comparable to a cheap laptop but has many other features come with raspberry pi can be used in future information science school projects. Also, when playing games we always preferred joystick over arrow keys on the keyboard, isn’t it?

2. There are plenty of arcade machine tutorials showing us how to build an tabletop arcade machine, so why do we want to build our own?
> First of all, the commercial arcade machine does not come with a keyboard which is critical for a developer. Secondly, the current arcade machine usually uses RetorPie as the raspbian OS, and the terminal environment is not that straightforward as a desktop OS. Last but not least, in some commercial arcade build such as Picade the joystick interfaces with raspberry pi via a GPIO encoder board. The compatibility between the encoder board and RetroPie highly depends on the company which provides the board. In a long run, it is in general desired to work with general joysticks with encoders via USB communications.


# The components of a tabletop Arcade machine
